export const headers = {
  'X-PER-PAGE': 5,
  'X-PAGE': 1,
  'X-TOTAL': 13,
  'X-TOTAL_PAGES': 1,
  'X-NEXT-PAGE': null,
  'X-PREVIOUS-PAGE': null,
};
export const reposServerResponse = [
  {
    destroy_path: 'path',
    id: '123',
    location: 'location',
    path: 'foo',
    tags_path: 'tags_path',
  },
  {
    destroy_path: 'path_',
    id: '456',
    location: 'location_',
    path: 'bar',
    tags_path: 'tags_path_',
  },
];

export const registryServerResponse = [
  {
    name: 'centos7',
    short_revision: 'b118ab5b0',
    revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
    total_size: 679,
    layers: 19,
    location: 'location',
    created_at: 1505828744434,
    destroy_path: 'path_',
  },
  {
    name: 'centos6',
    short_revision: 'b118ab5b0',
    revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
    total_size: 679,
    layers: 19,
    location: 'location',
    created_at: 1505828744434,
  },
];

export const imagesListResponse = {
  data: [
    {
      path: 'foo',
      location: 'location',
      destroy_path: 'path',
    },
    {
      path: 'bar',
      location: 'location-2',
      destroy_path: 'path-2',
    },
  ],
  headers,
};

export const tagsListResponse = {
  data: [
    {
      name: 'centos6',
      revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
      short_revision: 'b118ab5b0',
      size: 19,
      layers: 10,
      location: 'location',
      path: 'bar',
      created_at: 1505828744434,
      destroy_path: 'path',
    },
    {
      name: 'test-tag',
      revision: 'b969de599faea2b3d9b6605a8b0897261c571acaa36db1bdc7349b5775b4e0b4',
      short_revision: 'b969de599',
      size: 19,
      layers: 10,
      path: 'foo',
      location: 'location-2',
      created_at: 1505828744434,
    },
  ],
  headers,
};

export const imagePagination = {
  perPage: 10,
  page: 1,
  total: 14,
  totalPages: 2,
  nextPage: 2,
};
