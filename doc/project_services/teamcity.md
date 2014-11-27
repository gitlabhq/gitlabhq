# Jetbrains Teamcity CI Service

GitLab provides integration with Jetbrains Teamcity for continuous integration.
When configured Merge requests will display CI status showing whether the build
is pending, failed, or completed successfully. It also provides a link to the 
Teamcity build page for more information.

There are a few things that need to be configured in a Teamcity build 
configuration before GitLab can integrate.

## Setup

### Complete these steps in Teamcity:

1. Create new build configuration.
1. Add a VCS corresponding to your gitlab project
1. Select the 'Triggers' tab.
1. Add VCS Trigger for Teamcity to periodically poll for new commits and build them.
1. Configure your build steps.

Teamcity is now ready to trigger builds when new changes are pushed to GitLab.
Next, set up the Teamcity service in GitLab.

### Complete these steps in GitLab:

1. Navigate to the project you want to configure to trigger builds.
1. Select 'Settings' in the top navigation.
1. Select 'Services' in the left navigation.
1. Click 'Teamcity CI'
1. Select the 'Active' checkbox.
1. Enter the base URL of your Teamcity server. 'https://teamcity.example.com'
1. Enter the Build Configuration Id from your Teamcity build configuration.
1. Enter username and password for a Teamcity user with Project viewer role
assigned.
1. Save.
