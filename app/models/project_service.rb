class ProjectService < ActiveRecord::Base
  attr_accessible :active, :data, :project_id, :service_hook_name

  validates :project_id, presence: true
  validates :service_hook_name, presence: true

  serialize :data, Hash

  after_initialize :define_methods

  def define_methods
    self.service.schema.each do |type, name|
      define_singleton_method(name) { self.data[name.to_sym] }
      define_singleton_method("#{name}=") do |value|
        self.data[name.to_sym] = value
      end
      self.class.attr_accessible name.to_sym
    end
  end

  def service
    @service ||= Service.services.select { |service| service.hook_name == self.service_hook_name }.first
  end

  def data_fields(&block)
    self.service.schema.each do |type, name|
      if type == :boolean
        type = :check_box
      else
        type = :text_field
      end
      yield name.to_sym, type
    end
  end

end
