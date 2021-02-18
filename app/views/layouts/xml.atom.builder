# frozen_string_literal: true

xml.instruct!
xml.feed 'xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:media' => 'http://search.yahoo.com/mrss/' do
  xml << yield
end
