# frozen_string_literal: true

module BulkImports
  class Stage
    include Singleton

    CONFIG = {
      group: {
        pipeline: BulkImports::Groups::Pipelines::GroupPipeline,
        stage: 0
      },
      avatar: {
        pipeline: BulkImports::Groups::Pipelines::GroupAvatarPipeline,
        stage: 1
      },
      subgroups: {
        pipeline: BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline,
        stage: 1
      },
      members: {
        pipeline: BulkImports::Groups::Pipelines::MembersPipeline,
        stage: 1
      },
      labels: {
        pipeline: BulkImports::Groups::Pipelines::LabelsPipeline,
        stage: 1
      },
      milestones: {
        pipeline: BulkImports::Groups::Pipelines::MilestonesPipeline,
        stage: 1
      },
      badges: {
        pipeline: BulkImports::Groups::Pipelines::BadgesPipeline,
        stage: 1
      },
      boards: {
        pipeline: BulkImports::Groups::Pipelines::BoardsPipeline,
        stage: 2
      },
      finisher: {
        pipeline: BulkImports::Groups::Pipelines::EntityFinisher,
        stage: 3
      }
    }.freeze

    def self.pipelines
      instance.pipelines
    end

    def self.pipeline_exists?(name)
      pipelines.any? do |(_, pipeline)|
        pipeline.to_s == name.to_s
      end
    end

    def pipelines
      @pipelines ||= config
        .values
        .sort_by { |entry| entry[:stage] }
        .map do |entry|
          [entry[:stage], entry[:pipeline]]
        end
    end

    private

    def config
      @config ||= CONFIG
    end
  end
end

::BulkImports::Stage.prepend_mod_with('BulkImports::Stage')
