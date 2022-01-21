# Run PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell?view=powershell-7#with-administrative-privileges-run-as-administrator
# Create a folder somewhere on your system, for example: C:\GitLab-Runner
New-Item -Path 'C:\GitLab-Runner' -ItemType Directory

# Change to the folder
cd 'C:\GitLab-Runner'

# Download binary
Invoke-WebRequest -Uri "${GITLAB_CI_RUNNER_DOWNLOAD_LOCATION}" -OutFile "gitlab-runner.exe"

# Register the runner (steps below), then run
.\gitlab-runner.exe install
.\gitlab-runner.exe start
