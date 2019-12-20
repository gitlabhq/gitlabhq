# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

Gitlab.ee do
  require 'elasticsearch/model'

  ### Monkey patches

  Elasticsearch::Model::Response::Records.prepend GemExtensions::Elasticsearch::Model::Response::Records
  Elasticsearch::Model::Adapter::Multiple::Records.prepend GemExtensions::Elasticsearch::Model::Adapter::Multiple::Records
  Elasticsearch::Model::Indexing::InstanceMethods.prepend GemExtensions::Elasticsearch::Model::Indexing::InstanceMethods
  Elasticsearch::Model::Adapter::ActiveRecord::Importing.prepend GemExtensions::Elasticsearch::Model::Adapter::ActiveRecord::Importing
  Elasticsearch::Model::Client::InstanceMethods.prepend GemExtensions::Elasticsearch::Model::Client
  Elasticsearch::Model::Client::ClassMethods.prepend GemExtensions::Elasticsearch::Model::Client
  Elasticsearch::Model::ClassMethods.prepend GemExtensions::Elasticsearch::Model::Client
  Elasticsearch::Model.singleton_class.prepend GemExtensions::Elasticsearch::Model::Client

  ### Modified from elasticsearch-model/lib/elasticsearch/model.rb

  [
    Elasticsearch::Model::Client::ClassMethods,
    Elasticsearch::Model::Naming::ClassMethods,
    Elasticsearch::Model::Indexing::ClassMethods,
    Elasticsearch::Model::Searching::ClassMethods
  ].each do |mod|
    Elasticsearch::Model::Proxy::ClassMethodsProxy.include mod
  end

  [
    Elasticsearch::Model::Client::InstanceMethods,
    Elasticsearch::Model::Naming::InstanceMethods,
    Elasticsearch::Model::Indexing::InstanceMethods,
    Elasticsearch::Model::Serializing::InstanceMethods
  ].each do |mod|
    Elasticsearch::Model::Proxy::InstanceMethodsProxy.include mod
  end

  Elasticsearch::Model::Proxy::InstanceMethodsProxy.class_eval <<-CODE, __FILE__, __LINE__ + 1
    def as_indexed_json(options={})
      target.respond_to?(:as_indexed_json) ? target.__send__(:as_indexed_json, options) : super
    end
  CODE
end
