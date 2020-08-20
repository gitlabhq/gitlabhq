# Run PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell?view=powershell-7#with-administrative-privileges-run-as-administrator
# Create a folder somewhere in your system ex.: C:\GitLab-Runner
New-Item -Path 'C:\GitLab-Runner' -ItemType Directory

# Enter the folder
cd 'C:\GitLab-Runner'

# Dowload binary
Invoke-WebRequest -Uri "${GITLAB_CI_RUNNER_DOWNLOAD_LOCATION}" -OutFile "gitlab-runner.exe"

# Register the Runner (steps below), then run
.\gitlab-runner.exe install
.\gitlab-runner.exe start
