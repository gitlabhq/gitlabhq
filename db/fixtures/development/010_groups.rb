Group.seed(:id, [
  { id: 100, name: "Gitlab", path: 'gitlab', owner_id: 1},
  { id: 101, name: "Rails", path: 'rails', owner_id: 1 },
  { id: 102, name: "KDE", path: 'kde', owner_id: 1 }
])

Project.seed(:id, [
  { id: 10, name: "kdebase", path: "kdebase", owner_id: 1, namespace_id: 102 },
  { id: 11, name: "kdelibs", path: "kdelibs", owner_id: 1, namespace_id: 102 },
  { id: 12, name: "amarok",  path: "amarok",  owner_id: 1, namespace_id: 102 }
])
