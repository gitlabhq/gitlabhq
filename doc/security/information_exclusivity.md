# Information exclusivity

Git is a distributed version control system (DVCS).
This means that everyone that works with the source code has a local copy of the complete repository.
In GitLab every project member that is not a guest (so reporters, developers and masters) can clone the repository to get a local copy.
After obtaining this local copy the user can upload the full repository anywhere, including another project under their control or another server.
The consequence is that you can't build access controls that prevent the intentional sharing of source code by users that have access to the source code.
This is an inherent feature of a DVCS and all git management systems have this limitation.
Obviously you can take steps to prevent unintentional sharing and information destruction, this is why only some people are allowed to invite others and nobody can force push a protected branch.
