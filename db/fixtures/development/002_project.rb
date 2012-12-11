Group.seed(:id, [
  { id: 100, name: "Brightbox", path: 'brightbox', owner_id: 1 },
  { id: 101, name: "KDE", path: 'kde', owner_id: 1 },
])

Project.seed(:id, [
  { id: 1, name: "Underscore.js", path: "underscore", owner_id: 1 },
  { id: 2, name: "Diaspora", path: "diaspora", owner_id: 1 },
  { id: 3, namespace_id: 100, name: "Brightbox CLI", path: "brightbox-cli", owner_id: 1 },
  { id: 4, namespace_id: 100, name: "Puppet", path: "puppet", owner_id: 1 },
  { id: 5, namespace_id: 101, name: "kdebase", path: "kdebase", owner_id: 1},
  { id: 6, namespace_id: 101, name: "kdelibs", path: "kdelibs", owner_id: 1},
  { id: 7, namespace_id: 101, name: "amarok",  path: "amarok",  owner_id: 1},
])
