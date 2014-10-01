module SharedSearch
  include Spinach::DSL

  def search_snippet_contents(query)
    visit "/search?search=#{URI::encode(query)}&snippets=true&scope=snippet_blobs"
  end

  def search_snippet_titles(query)
    visit "/search?search=#{URI::encode(query)}&snippets=true&scope=snippet_titles"
  end
end
