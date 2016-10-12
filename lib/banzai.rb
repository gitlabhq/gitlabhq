module Banzai
  def self.render(text, context = {})
    Renderer.render(text, context)
  end

  def self.render_field(object, field)
    Renderer.render_field(object, field)
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
