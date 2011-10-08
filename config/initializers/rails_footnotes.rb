if defined?(Footnotes) && Rails.env.development?
  Footnotes.run! # first of all

  # ... other init code
end
