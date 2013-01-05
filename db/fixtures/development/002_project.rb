Group.seed(:id, [
  { id: 99,  name: "GitLab", path: 'gitlab', owner_id: 1 },
  { id: 100, name: "Brightbox", path: 'brightbox', owner_id: 1 },
  { id: 101, name: "KDE", path: 'kde', owner_id: 1 },
])

Project.seed(:id, [

  # Global
  { id: 1, name: "Underscore.js", path: "underscore", creator_id: 1 },
  { id: 2, name: "Diaspora", path: "diaspora", creator_id: 1 },

  # Brightbox
  { id: 3, namespace_id: 100, name: "Brightbox CLI", path: "brightbox-cli", creator_id: 1 },
  { id: 4, namespace_id: 100, name: "Puppet", path: "puppet", creator_id: 1 },

  # KDE
  { id: 5, namespace_id: 101, name: "kdebase", path: "kdebase", creator_id: 1},
  { id: 6, namespace_id: 101, name: "kdelibs", path: "kdelibs", creator_id: 1},
  { id: 7, namespace_id: 101, name: "amarok",  path: "amarok",  creator_id: 1},

  # GitLab
  { id: 8,  namespace_id: 99, name: "gitlabhq", path: "gitlabhq", creator_id: 1},
  { id: 9,  namespace_id: 99, name: "gitlab-ci",  path: "gitlab-ci",  creator_id: 1},
  { id: 10, namespace_id: 99, name: "gitlab-recipes",  path: "gitlab-recipes",  creator_id: 1},
])
