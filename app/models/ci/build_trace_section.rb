# frozen_string_literal: true

module Ci
  class BuildTraceSection < ApplicationRecord
    extend SuppressCompositePrimaryKeyWarning
    extend Gitlab::Ci::Model
    include IgnorableColumns

    belongs_to :build, class_name: 'Ci::Build'
    belongs_to :project
    belongs_to :section_name, class_name: 'Ci::BuildTraceSectionName'

    validates :section_name, :build, :project, presence: true, allow_blank: false

    ignore_column :build_id_convert_to_bigint, remove_with: '14.2', remove_after: '2021-08-22'
  end
end
