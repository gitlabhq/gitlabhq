# frozen_string_literal: true

require 'gitlab-http'
require_relative 'helpers/groups'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. It regenerates the Zoekt version compatibility table in
  # `doc/integration/zoekt/_index.md` and opens a merge request when the published table is out of date.
  #
  # For each released GitLab minor version since Zoekt moved to limited availability it reads:
  #
  # - `GITLAB_ZOEKT_VERSION` on the `X-Y-stable-ee` branch: the indexer version the release is built and tested against.
  # - The `gitlab-zoekt` dependency in `Chart.yaml` on the matching `gitlab-org/charts/gitlab` stable branch: the chart
  #   version that ships with the release.
  # - The indexer image tag in `values.yaml` of that `gitlab-zoekt` chart version, to warn in the merge request
  #   description when the chart deploys a different indexer than the release is tested against.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::UpdateZoektCompatibilityMatrix
  # ```
  class UpdateZoektCompatibilityMatrix < ::Gitlab::Housekeeper::Keep
    Error = Class.new(StandardError)
    Release = Struct.new(:gitlab_version, :indexer_version, :chart_version, :chart_indexer_version, keyword_init: true)

    DOC_PATH = 'doc/integration/zoekt/_index.md'
    SECTION_HEADING = '## Version compatibility'
    API_URL = 'https://gitlab.com/api/v4'
    GITLAB_PROJECT = 'gitlab-org/gitlab'
    CHARTS_PROJECT = 'gitlab-org/charts/gitlab'
    ZOEKT_CHART_PROJECT = 'gitlab-org/cloud-native/charts/gitlab-zoekt'
    GROUP_LABEL = 'group::global search'

    # Zoekt moved to limited availability in GitLab 18.6.
    FIRST_VERSION = [18, 6].freeze
    LAST_MINOR_OF_MAJOR = 11
    # The charts/gitlab major version is the GitLab major version minus 9: GitLab 18.x ships with chart 9.x.
    CHARTS_MAJOR_OFFSET = 9

    HEADERS = ['GitLab version', '`gitlab-zoekt-indexer` version', '`gitlab-zoekt` chart version'].freeze

    def each_identified_change
      table = generate_table
      return if table == published_table

      change = ::Gitlab::Housekeeper::Change.new
      # A single stable identifier keeps one MR open at a time, updated in place when the table changes again.
      change.identifiers = [self.class.name.demodulize]
      change.context = { table: table, releases: releases }
      yield(change)
    end

    def make_change!(change)
      table = change.context[:table]
      doc = File.read(DOC_PATH)

      File.write(DOC_PATH, replace_table(doc, table))

      change.title = 'Update Zoekt version compatibility table'
      change.changed_files = [DOC_PATH]
      change.labels = ['documentation', 'type::maintenance', 'maintenance::workflow', 'Category:Code Search',
        GROUP_LABEL]
      change.description = description(change.context[:releases])

      # Seeding with the latest GitLab version keeps the assignee stable across runs and rotates it each release.
      assignee = groups_helper.pick_reviewer(
        groups_helper.group_for_group_label(GROUP_LABEL),
        change.identifiers + [change.context[:releases].last.gitlab_version]
      )
      change.assignees = [assignee] if assignee

      change
    end

    # The identifiers never change, so a closed MR must not stop the keep from opening the next one.
    def recreate_when_closed?
      true
    end

    private

    def releases
      @releases ||= begin
        major, minor = FIRST_VERSION
        result = []

        while released?(major, minor)
          result << fetch_release(major, minor)

          if minor == LAST_MINOR_OF_MAJOR
            major += 1
            minor = 0
          else
            minor += 1
          end
        end

        raise Error, 'No released GitLab versions found' if result.empty?

        result
      end
    end

    def released?(major, minor)
      !api_get("/projects/#{encode(GITLAB_PROJECT)}/repository/tags/v#{major}.#{minor}.0-ee", allow_missing: true).nil?
    end

    def fetch_release(major, minor)
      indexer_version = raw_file(GITLAB_PROJECT, 'GITLAB_ZOEKT_VERSION', "#{major}-#{minor}-stable-ee")
      charts_branch = "#{major - CHARTS_MAJOR_OFFSET}-#{minor}-stable"
      chart_yaml = load_yaml(raw_file(CHARTS_PROJECT, 'Chart.yaml', charts_branch), "Chart.yaml on #{charts_branch}")
      dependency = Array(chart_yaml['dependencies']).find { |d| d['name'] == 'gitlab-zoekt' }
      raise Error, "No gitlab-zoekt chart dependency for GitLab #{major}.#{minor}" unless dependency

      chart_version = yaml_string(dependency['version'], "gitlab-zoekt chart version for GitLab #{major}.#{minor}")
      values_yaml = load_yaml(raw_file(ZOEKT_CHART_PROJECT, 'values.yaml', "v#{chart_version}"),
        "values.yaml in gitlab-zoekt chart #{chart_version}")
      chart_indexer_tag = yaml_string(values_yaml.dig('indexer', 'image', 'tag'),
        "indexer.image.tag in gitlab-zoekt chart #{chart_version}")

      Release.new(
        gitlab_version: "#{major}.#{minor}",
        indexer_version: normalize_version(indexer_version),
        chart_version: chart_version,
        chart_indexer_version: normalize_version(chart_indexer_tag)
      )
    end

    # YAML.safe_load returns nil for an empty document, which would otherwise raise a NoMethodError
    # on the first hash access instead of this keep's own Error.
    def load_yaml(content, name)
      yaml = YAML.safe_load(content)
      raise Error, "#{name} is empty or not a YAML mapping" unless yaml.is_a?(Hash)

      yaml
    end

    # An unquoted YAML value such as `4.10` loads as the Float 4.1, so only accept strings.
    def yaml_string(value, name)
      raise Error, "#{name} is missing or is not a string" unless value.is_a?(String) && !value.empty?

      value
    end

    # v1.11.2-abc123 -> 1.11.2
    def normalize_version(version)
      version.to_s.strip.delete_prefix('v').split('-').first
    end

    def generate_table
      rows = releases
        .chunk_while { |a, b| [a.indexer_version, a.chart_version] == [b.indexer_version, b.chart_version] }
        .map { |group| [version_range(group), group.first.indexer_version, group.first.chart_version] }
        .reverse

      widths = HEADERS.each_with_index.map { |header, i| [header, *rows.map { |row| row[i] }].map(&:length).max }
      format_row = ->(cells) { "| #{cells.each_with_index.map { |cell, i| cell.ljust(widths[i]) }.join(' | ')} |" }

      [
        format_row.call(HEADERS),
        "|#{widths.map { |w| '-' * (w + 2) }.join('|')}|",
        *rows.map { |row| format_row.call(row) }
      ].join("\n")
    end

    def version_range(group)
      first = group.first.gitlab_version
      last = group.last.gitlab_version

      return first if group.size == 1
      return "#{first} and #{last}" if group.size == 2

      "#{first} to #{last}"
    end

    def published_table
      lines = File.read(DOC_PATH).lines
      range = table_range(lines)
      return '' unless range

      lines[range].map(&:chomp).join("\n")
    end

    # Returns the index range of the table rows that directly follow the section heading and its intro paragraph.
    def table_range(lines)
      heading = lines.index { |line| line.chomp == SECTION_HEADING }
      raise Error, "#{SECTION_HEADING} not found in #{DOC_PATH}" unless heading

      first_row = ((heading + 1)...lines.size).find { |i| lines[i].start_with?('|', '## ') }
      return if first_row.nil? || lines[first_row].start_with?('## ')

      row_count = lines[first_row..].take_while { |line| line.start_with?('|') }.size
      first_row...(first_row + row_count)
    end

    def replace_table(doc, table)
      lines = doc.lines
      range = table_range(lines)
      raise Error, "No table found under #{SECTION_HEADING} in #{DOC_PATH}" unless range

      lines[range] = table.lines.map { |line| "#{line.chomp}\n" }
      lines.join
    end

    def description(releases)
      drift = releases.reject { |release| release.indexer_version == release.chart_indexer_version }

      description = <<~MARKDOWN
        Updates the [Zoekt version compatibility table](https://docs.gitlab.com/integration/zoekt/#version-compatibility)
        from the versions pinned for each released GitLab version:

        - `gitlab-zoekt-indexer` version: `GITLAB_ZOEKT_VERSION` on the `X-Y-stable-ee` branch.
        - `gitlab-zoekt` chart version: the `gitlab-zoekt` dependency in `Chart.yaml` on the matching
          [`gitlab-org/charts/gitlab`](https://gitlab.com/gitlab-org/charts/gitlab) stable branch.

        This MR was generated by `Keeps::UpdateZoektCompatibilityMatrix`.
      MARKDOWN

      return description if drift.empty?

      warnings = drift.map do |release|
        "- GitLab #{release.gitlab_version}: `GITLAB_ZOEKT_VERSION` is #{release.indexer_version}, but " \
          "`gitlab-zoekt` chart #{release.chart_version} deploys indexer #{release.chart_indexer_version}."
      end

      <<~MARKDOWN
        #{description}
        ## Chart and indexer versions differ

        The `gitlab-zoekt` chart shipped with these releases deploys a different indexer version than the release is
        tested against. Release a `gitlab-zoekt` chart with the matching indexer image tag and bump it in
        `gitlab-org/charts/gitlab`:

        #{warnings.join("\n")}
      MARKDOWN
    end

    def raw_file(project, path, ref)
      api_get("/projects/#{encode(project)}/repository/files/#{encode(path)}/raw?ref=#{encode(ref)}")
    end

    def api_get(path, allow_missing: false)
      response = Gitlab::HTTP_V2.get("#{API_URL}#{path}") # rubocop:disable Gitlab/HttpV2 -- Only requires the gem, so Gitlab::HTTP_V2 is unconfigured here (matches keeps/helpers/groups.rb)

      return if allow_missing && response.code == 404
      raise Error, "GET #{path} failed with response code #{response.code}" unless (200..299).cover?(response.code)

      response.body
    end

    def encode(value)
      ERB::Util.url_encode(value)
    end

    def groups_helper
      ::Keeps::Helpers::Groups.instance
    end
  end
end
