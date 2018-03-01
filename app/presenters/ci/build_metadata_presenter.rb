module Ci
  class BuildMetadataPresenter < Gitlab::View::Presenter::Delegated

    TIMEOUT_SOURCES = {
        unknown_timeout_source: nil,
        project_timeout_source: 'project',
        runner_timeout_source: 'runner'
    }.freeze

    presents :metadata

    def timeout_source
      return unless metadata.timeout_source?

      TIMEOUT_SOURCES[metadata.timeout_source.to_sym] ||
          metadata.timeout_source
    end

  end
end
