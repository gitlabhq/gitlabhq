# Provides an ActiveRecord-like interface to a model whose data is not persisted to a database.
module StaticModel
  extend ActiveSupport::Concern

  module ClassMethods
    # Used by ActiveRecord's polymorphic association to set object_id
    def primary_key
      'id'
    end

    # Used by ActiveRecord's polymorphic association to set object_type
    def base_class
      self
    end
  end

  # Used by AR for fetching attributes
  #
  # Pass it along if we respond to it.
  def [](key)
    send(key) if respond_to?(key)
  end

  def to_param
    id
  end

  def new_record?
    false
  end

  def persisted?
    false
  end

  def destroyed?
    false
  end
end
