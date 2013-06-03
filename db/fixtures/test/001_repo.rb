require 'fileutils'

print "Unpacking seed repository..."

SEED_REPO = 'seed_project.tar.gz'
REPO_PATH = Rails.root.join('tmp', 'repositories')

# Make whatever directories we need to make
FileUtils.mkdir_p(REPO_PATH)

# Copy the archive to the repo path
FileUtils.cp(Rails.root.join('spec', SEED_REPO), REPO_PATH)

# chdir to the repo path
FileUtils.cd(REPO_PATH) do
  # Extract the archive
  `tar -xf #{SEED_REPO}`

  # Remove the copy
  FileUtils.rm(SEED_REPO)
end
puts ' done.'
print "Creating seed satellite..."

SATELLITE_PATH = Rails.root.join('tmp', 'satellite')
# Make directory
FileUtils.mkdir_p(SATELLITE_PATH)
# Clear any potential directory
FileUtils.rm_rf("#{SATELLITE_PATH}/gitlabhq")
#  Chdir, clone from the seed
FileUtils.cd(SATELLITE_PATH) do
  # Clone the satellite

  `git clone --quiet #{REPO_PATH}/gitlabhq #{SATELLITE_PATH}/gitlabhq`
end
puts ' done.'
