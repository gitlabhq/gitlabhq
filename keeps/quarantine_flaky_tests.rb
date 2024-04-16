# frozen_string_literal: true

require 'gitlab-http'

require_relative 'helpers/groups'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep.
  # This keep will fetch any `test` + `failure::flaky-test` + `flakiness::1` issues,
  # without the `QA` nor `quarantine` labels and open quarantine merge requests for them.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::QuarantineFlakyTests
  # ```
  class QuarantineFlakyTests < ::Gitlab::Housekeeper::Keep
    MINIMUM_REMAINING_RATE = 25
    FLAKINESS_1_TEST_ISSUES_URL = "https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/issues/?order_by=updated_at&state=opened&labels%5B%5D=test&labels%5B%5D=failure%3A%3Aflaky-test&labels%5B%5D=flakiness%3A%3A1&not%5Blabels%5D%5B%5D=QA&not%5Blabels%5D%5B%5D=quarantine&per_page=20"
    EXAMPLE_LINE_REGEX = /([\w'",])? do$/

    def each_change
      each_very_flaky_issue do |flaky_issue|
        change = prepare_change(flaky_issue)

        yield(change) if change
      end
    end

    private

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def prepare_change(flaky_issue)
      match = flaky_issue['description'].match(%r{\| File URL \| \[`(?<filename>[\w\/\.]+)#L(?<line_number>\d+)`\]})
      return unless match

      filename = match[:filename]
      line_number = match[:line_number].to_i

      match = flaky_issue['description'].match(%r{\| Description \| (?<description>.+) \|})
      return unless match

      description = match[:description]

      file = File.expand_path("../#{filename}", __dir__)
      full_file_content = File.read(file)

      file_lines = full_file_content.lines
      return unless file_lines[line_number - 1].match?(EXAMPLE_LINE_REGEX)

      file_lines[line_number - 1].sub!(EXAMPLE_LINE_REGEX, "\\1, quarantine: '#{flaky_issue['web_url']}' do")

      if file_lines[line_number - 1].size > 120
        file_lines[line_number - 1].sub!(
          /\n\z/,
          " # rubocop:disable Layout/LineLength -- We prefer to keep it on a single line, for simplicity sake\n"
        )
      end

      File.write(file, file_lines.join)

      construct_change(filename, line_number, description, flaky_issue)
    end

    def each_very_flaky_issue
      query_api(FLAKINESS_1_TEST_ISSUES_URL) do |flaky_test_issue|
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
      http_response = Gitlab::HTTP.get(
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
        The #{description} test has the `flakiness::1` label set, which means it has more than 1000 flakiness reports.

        This MR quarantines the test. This is a discussion starting point to let the responsible group know about the flakiness
        so that they can take action:

        - accept the merge request and schedule to improve the test
        - close the merge request in favor of another merge request to delete the test

        Related to #{flaky_issue['web_url']}.
        MARKDOWN

        group_label = flaky_issue['labels'].grep(/group::/).first
        change.labels = [
          'maintenance::refactor',
          'test',
          'failure::flaky-test',
          'pipeline:expedite',
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
