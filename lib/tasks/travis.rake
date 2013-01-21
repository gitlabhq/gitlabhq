desc "Travis run tests"
task :travis => [
  :spinach,
  :spec
]
