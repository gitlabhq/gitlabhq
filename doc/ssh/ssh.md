# SSH keys

SSH key allows you to establish a secure connection between your computer and GitLab

Before generating an SSH key, check if your system already has one by running `cat ~/.ssh/id_rsa.pub` If your see a long string starting with `ssh-rsa` or `ssh-dsa`, you can skip the ssh-keygen step.

To generate a new SSH key just open your terminal and use code below. The ssh-keygen command prompts you for a location and filename to store the key pair and for a password. When prompted for the location and filename you can press enter to use the default. 
It is a best practice to use a password for an SSH key but it is not required and you can skip creating a password by pressing enter. 
Note that the password you choose here can't be altered or retrieved.

```bash
ssh-keygen -t rsa -C "$your_email"
```

Use the code below to show your public key.

```bash
cat ~/.ssh/id_rsa.pub
```

Copy-paste the key to the 'My SSH Keys' section under the 'SSH' tab in your user profile. Please copy the complete key starting with `ssh-` and ending with your username and host.
