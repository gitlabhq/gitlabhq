FROM busybox

# Declare volumes
VOLUME ["/var/opt/gitlab", "/var/log/gitlab", "/etc/gitlab"]
# Copy assets
COPY assets/gitlab.rb /etc/gitlab/

CMD /bin/sh
