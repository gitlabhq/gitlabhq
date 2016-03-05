module Banzai
  def self.render(text, context = {})
    Renderer.render(text, context)
  end

  def self.render_result(text, context = {})
    Renderer.render_result(text, context)
  end

  def self.pre_process(text, context)
    Renderer.pre_process(text, context)
  end

  def self.post_process(html, context)
    Renderer.post_process(html, context)
  end
end
