# frozen_string_literal: true

module Ci
  class PopulatePipelineService < BaseService
    attr_reader :pipeline

    SEQUENCE = [Gitlab::Ci::Pipeline::Chain::Validate::Abilities,
                Gitlab::Ci::Pipeline::Chain::Validate::Repository,
                Gitlab::Ci::Pipeline::Chain::Validate::Config,
                Gitlab::Ci::Pipeline::Chain::Skip,
                Gitlab::Ci::Pipeline::Chain::Populate,
                Gitlab::Ci::Pipeline::Chain::Create].freeze

    def execute(pipeline, seeds_block, complete_block, save_on_errors:)
      @pipeline = pipeline

      command = Gitlab::Ci::Pipeline::Chain::Command.new(
        pipeline: pipeline,
        project: project,
        current_user: current_user,
        save_incompleted: save_on_errors,
        seeds_block: seeds_block)

      sequence = Gitlab::Ci::Pipeline::Chain::Sequence
        .new(pipeline, command, SEQUENCE)

      sequence.build! do |pipeline, sequence|
        if sequence.complete?
          complete_block.call if complete_block
          pipeline.process!
        end
      end

      pipeline
    end
  end
end
