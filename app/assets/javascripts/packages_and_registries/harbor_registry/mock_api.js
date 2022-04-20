const mockRequestFn = (mockData) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(mockData);
    }, 2000);
  });
};
export const harborListResponse = () => {
  const harborListResponseData = {
    repositories: [
      {
        artifactCount: 1,
        creationTime: '2022-03-02T06:35:53.205Z',
        id: 25,
        name: 'shao/flinkx',
        projectId: 21,
        pullCount: 0,
        updateTime: '2022-03-02T06:35:53.205Z',
        location: 'demo.harbor.com/gitlab-cn/build/cng-images/gitlab-kas',
      },
      {
        artifactCount: 1,
        creationTime: '2022-03-02T06:35:53.205Z',
        id: 26,
        name: 'shao/flinkx1',
        projectId: 21,
        pullCount: 0,
        updateTime: '2022-03-02T06:35:53.205Z',
        location: 'demo.harbor.com/gitlab-cn/build/cng-images/gitlab-kas',
      },
      {
        artifactCount: 1,
        creationTime: '2022-03-02T06:35:53.205Z',
        id: 27,
        name: 'shao/flinkx2',
        projectId: 21,
        pullCount: 0,
        updateTime: '2022-03-02T06:35:53.205Z',
        location: 'demo.harbor.com/gitlab-cn/build/cng-images/gitlab-kas',
      },
    ],
    totalCount: 3,
    pageInfo: {
      hasNextPage: false,
      hasPreviousPage: false,
    },
  };

  return mockRequestFn(harborListResponseData);
};

export const getHarborRegistryImageDetail = () => {
  const harborRegistryImageDetailData = {
    artifactCount: 1,
    creationTime: '2022-03-02T06:35:53.205Z',
    id: 25,
    name: 'shao/flinkx',
    projectId: 21,
    pullCount: 0,
    updateTime: '2022-03-02T06:35:53.205Z',
    location: 'demo.harbor.com/gitlab-cn/build/cng-images/gitlab-kas',
    tagsCount: 10,
  };

  return mockRequestFn(harborRegistryImageDetailData);
};

export const harborTagsResponse = () => {
  const harborTagsResponseData = {
    tags: [
      {
        digest: 'sha256:7f386a1844faf341353e1c20f2f39f11f397604fedc475435d13f756eeb235d1',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:02310e655103823920157bc4410ea361dc638bc2cda59667d2cb1f2a988e264c',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:02310e655103823920157bc4410ea361dc638bc2cda59667d2cb1f2a988e264c',
        name: '02310e655103823920157bc4410ea361dc638bc2cda59667d2cb1f2a988e264c',
        revision: 'f53bde3d44699e04e11cf15fb415046a0913e2623d878d89bc21adb2cbda5255',
        shortRevision: 'f53bde3d4',
        createdAt: '2022-03-02T23:59:05+00:00',
        totalSize: '6623124',
      },
      {
        digest: 'sha256:4554416b84c4568fe93086620b637064ed029737aabe7308b96d50e3d9d92ed7',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:02deb4dddf177212b50e883d5e4f6c03731fad1a18cd27261736cd9dbba79160',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:02deb4dddf177212b50e883d5e4f6c03731fad1a18cd27261736cd9dbba79160',
        name: '02deb4dddf177212b50e883d5e4f6c03731fad1a18cd27261736cd9dbba79160',
        revision: 'e1fe52d8bab66d71bd54a6b8784d3b9edbc68adbd6ea87f5fa44d9974144ef9e',
        shortRevision: 'e1fe52d8b',
        createdAt: '2022-02-10T01:09:56+00:00',
        totalSize: '920760',
      },
      {
        digest: 'sha256:14f37b60e52b9ce0e9f8f7094b311d265384798592f783487c30aaa3d58e6345',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:03bc5971bab1e849ba52a20a31e7273053f22b2ddb1d04bd6b77d53a2635727a',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:03bc5971bab1e849ba52a20a31e7273053f22b2ddb1d04bd6b77d53a2635727a',
        name: '03bc5971bab1e849ba52a20a31e7273053f22b2ddb1d04bd6b77d53a2635727a',
        revision: 'c72770c6eb93c421bc496964b4bffc742b1ec2e642cdab876be7afda1856029f',
        shortRevision: 'c72770c6e',
        createdAt: '2021-12-22T04:48:48+00:00',
        totalSize: '48609053',
      },
      {
        digest: 'sha256:e925e3b8277ea23f387ed5fba5e78280cfac7cfb261a78cf046becf7b6a3faae',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:03f495bc5714bff78bb14293320d336afdf47fd47ddff0c3c5f09f8da86d5d19',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:03f495bc5714bff78bb14293320d336afdf47fd47ddff0c3c5f09f8da86d5d19',
        name: '03f495bc5714bff78bb14293320d336afdf47fd47ddff0c3c5f09f8da86d5d19',
        revision: '1ac2a43194f4e15166abdf3f26e6ec92215240490b9cac834d63de1a3d87494a',
        shortRevision: '1ac2a4319',
        createdAt: '2022-03-09T11:02:27+00:00',
        totalSize: '35141894',
      },
      {
        digest: 'sha256:7d8303fd5c077787a8c879f8f66b69e2b5605f48ccd3f286e236fb0749fcc1ca',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:05a4e58231e54b70aab2d6f22ba4fbe10e48aa4ddcbfef11c5662241c2ae4fda',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:05a4e58231e54b70aab2d6f22ba4fbe10e48aa4ddcbfef11c5662241c2ae4fda',
        name: '05a4e58231e54b70aab2d6f22ba4fbe10e48aa4ddcbfef11c5662241c2ae4fda',
        revision: 'cf8fee086701016e1a84e6824f0c896951fef4cce9d4745459558b87eec3232c',
        shortRevision: 'cf8fee086',
        createdAt: '2022-01-21T11:31:43+00:00',
        totalSize: '48716070',
      },
      {
        digest: 'sha256:b33611cefe20e4a41a6e0dce356a5d7ef3c177ea7536a58652f5b3a4f2f83549',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:093d2746876997723541aec8b88687a4cdb3b5bbb0279c5089b7891317741a9a',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:093d2746876997723541aec8b88687a4cdb3b5bbb0279c5089b7891317741a9a',
        name: '093d2746876997723541aec8b88687a4cdb3b5bbb0279c5089b7891317741a9a',
        revision: '1a4b48198b13d55242c5164e64d41c4e9f75b5d9506bc6e0efc1534dd0dd1f15',
        shortRevision: '1a4b48198',
        createdAt: '2022-01-21T11:31:51+00:00',
        totalSize: '6623127',
      },
      {
        digest: 'sha256:d25c3c020e2dbd4711a67b9fe308f4cbb7b0bb21815e722a02f91c570dc5d519',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:09698b3fae81dfd6e02554dbc82930f304a6356c8f541c80e8598a42aed985f7',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:09698b3fae81dfd6e02554dbc82930f304a6356c8f541c80e8598a42aed985f7',
        name: '09698b3fae81dfd6e02554dbc82930f304a6356c8f541c80e8598a42aed985f7',
        revision: '03e2e2777dde01c30469ee8c710973dd08a7a4f70494d7dc1583c24b525d7f61',
        shortRevision: '03e2e2777',
        createdAt: '2022-03-02T23:58:20+00:00',
        totalSize: '911377',
      },
      {
        digest: 'sha256:fb760e4d2184e9e8e39d6917534d4610fe01009734698a5653b2de1391ba28f4',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:09b830c3eaf80d547f3b523d8e242a2c411085c349dab86c520f36c7b7644f95',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:09b830c3eaf80d547f3b523d8e242a2c411085c349dab86c520f36c7b7644f95',
        name: '09b830c3eaf80d547f3b523d8e242a2c411085c349dab86c520f36c7b7644f95',
        revision: '350e78d60646bf6967244448c6aaa14d21ecb9a0c6cf87e9ff0361cbe59b9012',
        shortRevision: '350e78d60',
        createdAt: '2022-01-19T13:49:14+00:00',
        totalSize: '48710241',
      },
      {
        digest: 'sha256:407250f380cea92729cbc038c420e74900f53b852e11edc6404fe75a0fd2c402',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:0d03504a17b467eafc8c96bde70af26c74bd459a32b7eb2dd189dd6b3c121557',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:0d03504a17b467eafc8c96bde70af26c74bd459a32b7eb2dd189dd6b3c121557',
        name: '0d03504a17b467eafc8c96bde70af26c74bd459a32b7eb2dd189dd6b3c121557',
        revision: '76038370b7f3904364891457c4a6a234897255e6b9f45d0a852bf3a7e5257e18',
        shortRevision: '76038370b',
        createdAt: '2022-01-24T12:56:22+00:00',
        totalSize: '280065',
      },
      {
        digest: 'sha256:ada87f25218542951ce6720c27f3d0758e90c2540bd129f5cfb9e15b31e07b07',
        location:
          'registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa/cache:0eb20a4a7cac2ebea821d420b3279654fe550fd8502f1785c1927aa84e5949eb',
        path:
          'gitlab-org/gitlab/gitlab-ee-qa/cache:0eb20a4a7cac2ebea821d420b3279654fe550fd8502f1785c1927aa84e5949eb',
        name: '0eb20a4a7cac2ebea821d420b3279654fe550fd8502f1785c1927aa84e5949eb',
        revision: '3d4b49a7bbb36c48bb721f4d0e76e7950bec3878ee29cdfdd6da39f575d6d37f',
        shortRevision: '3d4b49a7b',
        createdAt: '2022-02-17T17:37:52+00:00',
        totalSize: '48655767',
      },
    ],
    totalCount: 10,
    pageInfo: {
      hasNextPage: false,
      hasPreviousPage: true,
    },
  };

  return mockRequestFn(harborTagsResponseData);
};
