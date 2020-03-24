# frozen_string_literal: true

module Banzai
  # if you need to render markdown, then you probably need to post_process as well,
  # such as removing references that the current user doesn't have
  # permission to make
  def self.render_and_post_process(text, context = {})
    post_process(render(text, context), context)
  end

  def self.render_field_and_post_process(object, field, context = {})
    post_process(render_field(object, field, context), context)
  end

  def self.render(text, context = {})
    Renderer.render(text, context)
  end

  def self.render_field(object, field, context = {})
    Renderer.render_field(object, field, context)
  end

  def self.cache_collection_render(texts_and_contexts)
    Renderer.cache_collection_render(texts_and_contexts)
  end

  def self.render_result(text, context = {})
    Renderer.render_result(text, context)
  end

  def self.post_process(html, context)
    Renderer.post_process(html, context)
  end
end
