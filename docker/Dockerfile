# Data: docker run --name gitlab_data USER/IMAGE:TAG /bin/true
# Run:  docker run --detach --name gitlab --publish 8080:80 --publish 2222:22 --volumes-from gitlab_data USER/IMAGE:TAG

FROM ubuntu:14.04
MAINTAINER Vincent Robert <vincent.robert@genezys.net>

# Install required packages
RUN apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qy \
    	openssh-server \
    	wget \
    && apt-get clean

# Download & Install GitLab
RUN TMP_FILE=$(mktemp); \
    wget -q -O $TMP_FILE https://downloads-packages.s3.amazonaws.com/ubuntu-14.04/gitlab_7.5.1-omnibus.5.2.0.ci-1_amd64.deb \
    && dpkg -i $TMP_FILE \
    && rm -f $TMP_FILE

# Manage SSHD through runit
RUN mkdir -p /opt/gitlab/sv/sshd/supervise \
    && mkfifo /opt/gitlab/sv/sshd/supervise/ok \
    && printf "#!/bin/sh\nexec 2>&1\numask 077\nexec /usr/sbin/sshd -D" > /opt/gitlab/sv/sshd/run \
    && chmod a+x /opt/gitlab/sv/sshd/run \
    && ln -s /opt/gitlab/sv/sshd /opt/gitlab/service \
    && mkdir -p /var/run/sshd

# Expose web & ssh
EXPOSE 80 22

# Volume & configuration
VOLUME ["/var/opt/gitlab", "/var/log/gitlab", "/etc/gitlab"]
ADD gitlab.rb /etc/gitlab/

# Default is to run runit & reconfigure
CMD gitlab-ctl reconfigure > /var/log/gitlab/reconfigure.log & /opt/gitlab/embedded/bin/runsvdir-start
