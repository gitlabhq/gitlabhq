# create tmp dir if not exist
tmp_dir = File.join(Rails.root, "tmp")
Dir.mkdir(tmp_dir) unless File.exists?(tmp_dir)

# Create dir for test repo
repo_dir = File.join(Rails.root, "tmp", "tests")
Dir.mkdir(repo_dir) unless File.exists?(repo_dir)

`cp spec/seed_project.tar.gz tmp/tests/`
Dir.chdir(repo_dir)
`tar -xf seed_project.tar.gz`
3.times do |i|
`cp -r legit/ legit_#{i}/`
puts "Unpacked seed repo - tmp/tests/legit_#{i}"
end
