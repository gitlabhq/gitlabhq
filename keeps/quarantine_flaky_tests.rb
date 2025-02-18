# frozen_string_literal: true

require 'gitlab-http'

require_relative 'helpers/groups'

Gitlab::HTTP_V2.configure do |config|
  config.allowed_internal_uris = []
  config.log_exception_proc = ->(exception, extra_info) do
    p exception
    p extra_info
  end
  config.silent_mode_log_info_proc = ->(message, http_method) do
    p message
    p http_method
  end
  config.log_with_level_proc = ->(log_level, message_params) do
    p log_level
    p message_params
  end
end

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep.
  # This keep will fetch any `test` + `failure::flaky-test` + `flakiness::1` issues,
  # without the `QA` nor `quarantine` labels and open quarantine merge requests for them.
  #
  # You can run it individually with:
  #
  # ```
  # gdk start db
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::QuarantineFlakyTests
  # ```
  class QuarantineFlakyTests < ::Gitlab::Housekeeper::Keep
    MINIMUM_REMAINING_RATE = 25
    QUERY_URL_TEMPLATE = "https://gitlab.com/api/v4/projects/278964/issues/?order_by=updated_at&state=opened&labels[]=test&labels[]=failure::flaky-test&labels[]=%<flakiness_label>s&not[labels][]=QA&not[labels][]=quarantine&per_page=20"
    # https://rubular.com/r/OoeQIEwPkL1m7E
    EXAMPLE_LINE_REGEX = /\bit (?<description_and_metadata>[\w'",: \#\{\}]*(?:,\n)?[\w\'",: ]+?) do$/m
    FLAKINESS_LABELS = %w[flakiness::1 flakiness::2 severity::1].freeze

    def each_change
      FLAKINESS_LABELS.each do |flakiness_label|
        query_url = very_flaky_issues_query_url(flakiness_label)

        each_very_flaky_issue(query_url) do |flaky_issue|
          change = prepare_change(flaky_issue)

          yield(change) if change
        end
      end
    end

    private

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def very_flaky_issues_query_url(flakiness_label)
      format(QUERY_URL_TEMPLATE, { flakiness_label: flakiness_label })
    end

    def prepare_change(flaky_issue)
      match = flaky_issue['description'].match(%r{\| File URL \| \[`(?<filename>[\w\/\.]+)#L(?<line_number>\d+)`\]})
      return unless match

      filename = match[:filename]
      line_number = match[:line_number].to_i - 1

      match = flaky_issue['description'].match(%r{\| Description \| (?<description>.+) \|})
      return unless match

      description = match[:description]

      file = File.expand_path("../#{filename}", __dir__)
      full_file_content = File.read(file)

      file_lines = full_file_content.lines
      test_line = file_lines[line_number]

      unless test_line
        puts "#{file} doesn't have a line #{line_number}! Skipping."
        return
      end

      unless test_line.match?(EXAMPLE_LINE_REGEX)
        puts "Line #{line_number} of #{file} doesn't match #{EXAMPLE_LINE_REGEX}! See the line content:"
        puts "```\n#{test_line}\n```"
        puts "Skipping."
        return
      end

      puts "Quarantining #{flaky_issue['web_url']} (#{description})"

      file_lines[line_number].sub!(
        EXAMPLE_LINE_REGEX,
        "it \\k<description_and_metadata>, quarantine: '#{flaky_issue['web_url']}' do"
      )

      File.write(file, file_lines.join)

      ::Gitlab::Housekeeper::Shell.rubocop_autocorrect(file)

      construct_change(filename, line_number, description, flaky_issue)
    end

    def each_very_flaky_issue(url)
      query_api(url) do |flaky_test_issue|
        yield(flaky_test_issue)
      end
    end

    def query_api(url)
      get_result = {}

      begin
        print '.'
        url = get_result.fetch(:next_page_url) { url }

        puts "query_api: #{url}"
        get_result = get(url)

        results = get_result.delete(:results)

        case results
        when Array
          results.each { |result| yield(result) }
        else
          raise "Unexpected response: #{results.inspect}"
        end

        rate_limit_wait(get_result)
      end while get_result.delete(:more_pages)
    end

    def get(url)
      http_response = Gitlab::HTTP_V2.get( # rubocop:disable Gitlab/HttpV2 -- Not running inside rails application
        url,
        headers: {
          'User-Agent' => "GitLab-Housekeeper/#{self.class.name}",
          'Content-type' => 'application/json',
          'PRIVATE-TOKEN': ENV['HOUSEKEEPER_GITLAB_API_TOKEN']
        }
      )

      {
        more_pages: (http_response.headers['x-next-page'].to_s != ""),
        next_page_url: next_page_url(url, http_response),
        results: http_response.parsed_response,
        ratelimit_remaining: http_response.headers['ratelimit-remaining'],
        ratelimit_reset_at: http_response.headers['ratelimit-reset']
      }
    end

    def next_page_url(url, http_response)
      return unless http_response.headers['x-next-page'].present?

      next_page = "&page=#{http_response.headers['x-next-page']}"

      if url.include?('&page')
        url.gsub(/&page=\d+/, next_page)
      else
        url + next_page
      end
    end

    def rate_limit_wait(get_result)
      ratelimit_remaining = get_result.fetch(:ratelimit_remaining)
      ratelimit_reset_at = get_result.fetch(:ratelimit_reset_at)

      return if ratelimit_remaining.nil? || ratelimit_reset_at.nil?
      return if ratelimit_remaining.to_i >= MINIMUM_REMAINING_RATE

      ratelimit_reset_at = Time.at(ratelimit_reset_at.to_i)

      puts "Rate limit almost exceeded, sleeping for #{ratelimit_reset_at - Time.now} seconds"
      sleep(1) until Time.now >= ratelimit_reset_at
    end

    def construct_change(filename, line_number, description, flaky_issue)
      ::Gitlab::Housekeeper::Change.new.tap do |change|
        change.title = "Quarantine a flaky test"
        change.identifiers = [self.class.name.demodulize, filename, line_number.to_s]
        change.changed_files = [filename]
        change.description = <<~MARKDOWN
        The #{description}
        test matches one of the following conditions:
        1. has either ~"flakiness::1" or ~"flakiness::2" label set, which means the number of reported failures
        is at or above 95 percentile, indicating unusually high failure count.

        2. has ~"severity::1" label set, which means the number of reported failures
        [spiked and exceeded its daily threshold](https://gitlab.com/gitlab-org/ruby/gems/gitlab_quality-test_tooling/-/blob/c9bc10536b1f8d2d4a03c3e0b6099a40fe67ad26/lib/gitlab_quality/test_tooling/report/concerns/issue_reports.rb#L51).

        This MR quarantines the test. This is a discussion starting point to let the
        responsible group know about the flakiness so that they can take action:

        - accept the merge request and schedule the associated issue to improve the test
        - close the merge request in favor of another merge request to delete the test

        Please follow the
        [Flaky tests management process](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/flaky-tests-management-and-processes/#flaky-tests-management-process)
        to help us increase `master` stability.

        Please let us know your feedback in the
        [Engineering Productivity issue tracker](https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/issues).

        Related to #{flaky_issue['web_url']}.
        MARKDOWN

        group_label = flaky_issue['labels'].grep(/group::/).first
        change.labels = [
          'maintenance::refactor',
          'test',
          'failure::flaky-test',
          'pipeline::expedited',
          'quarantine',
          'quarantine::flaky',
          group_label
        ].compact

        if change.reviewers.empty? && group_label
          group_data = groups_helper.group_for_group_label(group_label)

          change.reviewers = groups_helper.pick_reviewer(group_data, change.identifiers) if group_data
        end
      end
    end
  end
end
