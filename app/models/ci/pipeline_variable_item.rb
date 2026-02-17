# frozen_string_literal: true

module Ci
  # A virtual model representing a pipeline variable. Used when pipeline
  # variables are handled in a non-DB storage context (e.g. object storage).
  class PipelineVariableItem
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations
    include GlobalID::Identification
    include Gitlab::Utils::StrongMemoize

    VARIABLE_TYPES = Enums::Ci::Variable::TYPES.keys.map(&:to_s).freeze
    MAX_KEY_LENGTH = 255
    # TODO: Max length TBD, or we may need to add bytesize validation;
    # see https://gitlab.com/gitlab-org/gitlab/-/issues/520159#note_3001941996
    MAX_VALUE_LENGTH = 500_000_000

    attribute :key, :string
    attribute :value, :string
    attribute :variable_type, :string, default: 'env_var'
    attribute :raw, :boolean, default: false

    validates :key,
      presence: true,
      length: { maximum: MAX_KEY_LENGTH },
      format: { with: /\A[a-zA-Z0-9_]+\z/,
                message: "can contain only letters, digits and '_'." }

    validates :value, length: { maximum: MAX_VALUE_LENGTH }
    validates :variable_type, inclusion: { in: VARIABLE_TYPES }
    validates :raw, inclusion: { in: [true, false] }

    alias_attribute :secret_value, :value
    alias_method :raw?, :raw

    # Required for auth check in Types::Ci::PipelineManualVariableType
    attr_reader :pipeline

    def initialize(pipeline:, **kwargs)
      @pipeline = pipeline

      super(**kwargs)
    end

    def key=(value)
      super(value.to_s.strip)
    end

    def variable_type=(value)
      # To mimic Ci::PipelineVariable variable_type enum behaviour
      if value.is_a?(Integer)
        enum_map = Enums::Ci::Variable::TYPES.invert
        value = enum_map[value]
      end

      super(value&.to_s)
    end

    # An ID is required for Types::Ci::PipelineManualVariableType
    def id
      Digest::SHA256.hexdigest("#{pipeline.id}/#{key}")
    end
    strong_memoize_attr :id

    def to_hash_variable
      { key: key, value: value, public: false, file: file?, raw: raw }
    end

    def file?
      variable_type == 'file'
    end

    def hook_attrs
      { key: key, value: value }
    end
  end
end
