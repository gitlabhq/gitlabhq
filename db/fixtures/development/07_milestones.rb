Milestone.seed(:id, [
  { id: 1,  project_id: 1, title: 'v' + Faker::Address.zip_code },
  { id: 2,  project_id: 1, title: 'v' + Faker::Address.zip_code },
  { id: 3,  project_id: 1, title: 'v' + Faker::Address.zip_code },
  { id: 4,  project_id: 2, title: 'v' + Faker::Address.zip_code },
  { id: 5,  project_id: 2, title: 'v' + Faker::Address.zip_code },

  { id: 6,  project_id: 2, title: 'v' + Faker::Address.zip_code },
  { id: 7,  project_id: 2, title: 'v' + Faker::Address.zip_code },
  { id: 8,  project_id: 3, title: 'v' + Faker::Address.zip_code },
  { id: 9,  project_id: 3, title: 'v' + Faker::Address.zip_code },
  { id: 11, project_id: 3, title: 'v' + Faker::Address.zip_code },
])

Milestone.all.map do |ml|
  ml.set_iid
  ml.save
end
