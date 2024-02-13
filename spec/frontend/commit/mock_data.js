export const mockDownstreamPipelinesGraphql = ({ includeSourceJobRetried = true } = {}) => ({
  nodes: [
    {
      id: 'gid://gitlab/Ci::Pipeline/612',
      path: '/root/job-log-sections/-/pipelines/612',
      project: {
        id: 'gid://gitlab/Project/21',
        name: 'job-log-sections',
        __typename: 'Project',
      },
      detailedStatus: {
        id: 'success-612-612',
        group: 'success',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/532',
        retried: includeSourceJobRetried ? false : null,
      },
      __typename: 'Pipeline',
    },
    {
      id: 'gid://gitlab/Ci::Pipeline/611',
      path: '/root/job-log-sections/-/pipelines/611',
      project: {
        id: 'gid://gitlab/Project/21',
        name: 'job-log-sections',
        __typename: 'Project',
      },
      detailedStatus: {
        id: 'success-611-611',
        group: 'success',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/531',
        retried: includeSourceJobRetried ? true : null,
      },
      __typename: 'Pipeline',
    },
    {
      id: 'gid://gitlab/Ci::Pipeline/609',
      path: '/root/job-log-sections/-/pipelines/609',
      project: {
        id: 'gid://gitlab/Project/21',
        name: 'job-log-sections',
        __typename: 'Project',
      },
      detailedStatus: {
        id: 'success-609-609',
        group: 'success',
        icon: 'status_success',
        label: 'passed',
        __typename: 'DetailedStatus',
      },
      sourceJob: {
        id: 'gid://gitlab/Ci::Bridge/530',
        retried: includeSourceJobRetried ? true : null,
      },
      __typename: 'Pipeline',
    },
  ],
  __typename: 'PipelineConnection',
});

const upstream = {
  id: 'gid://gitlab/Ci::Pipeline/610',
  path: '/root/trigger-downstream/-/pipelines/610',
  project: {
    id: 'gid://gitlab/Project/21',
    name: 'trigger-downstream',
    __typename: 'Project',
  },
  detailedStatus: {
    id: 'success-610-610',
    group: 'success',
    icon: 'status_success',
    label: 'passed',
    __typename: 'DetailedStatus',
  },
  __typename: 'Pipeline',
};

export const mockStages = [
  {
    name: 'build',
    title: 'build: passed',
    status: {
      __typename: 'DetailedStatus',
      id: 'success-409-409',
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/318#build',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/root/ci-project/-/pipelines/318#build',
    dropdown_path: '/root/ci-project/-/pipelines/318/stage.json?stage=build',
  },
];

export const mockPipelineStagesQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/320',
        stages: {
          nodes: [
            {
              __typename: 'CiStage',
              id: 'gid://gitlab/Ci::Stage/409',
              name: 'build',
              detailedStatus: {
                id: 'success-409-409',
                group: 'success',
                icon: 'status_success',
                __typename: 'DetailedStatus',
              },
            },
          ],
        },
      },
    },
  },
};

export const mockPipelineStatusResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/320',
        detailedStatus: {
          id: 'pending-320-320',
          icon: 'status_pending',
          text: 'Pending',
          detailsPath: '/root/ci-project/-/pipelines/320',
          __typename: 'DetailedStatus',
        },
        __typename: 'Pipeline',
      },
      __typename: 'Project',
    },
  },
};

export const mockDownstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        path: '/root/ci-project/-/pipelines/790',
        id: 'pipeline-1',
        downstream: mockDownstreamPipelinesGraphql(),
        upstream: null,
      },
      __typename: 'Project',
    },
  },
};

export const mockUpstreamDownstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        id: 'pipeline-1',
        path: '/root/ci-project/-/pipelines/790',
        downstream: mockDownstreamPipelinesGraphql(),
        upstream,
      },
      __typename: 'Project',
    },
  },
};

export const mockUpstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        id: 'pipeline-1',
        path: '/root/ci-project/-/pipelines/790',
        downstream: {
          nodes: [],
          __typename: 'PipelineConnection',
        },
        upstream,
      },
      __typename: 'Project',
    },
  },
};

export const sshSignatureProp = {
  __typename: 'SshSignature',
  verificationStatus: 'VERIFIED',
  keyFingerprintSha256: 'xxx',
};

export const gpgSignatureProp = {
  __typename: 'GpgSignature',
  verificationStatus: 'VERIFIED',
  gpgKeyPrimaryKeyid: 'yyy',
};

export const x509SignatureProp = {
  __typename: 'X509Signature',
  verificationStatus: 'VERIFIED',
  x509Certificate: {
    subject: 'CN=gitlab@example.org,OU=Example,O=World',
    subjectKeyIdentifier: 'BC:BC:BC:BC:BC:BC:BC:BC',
    x509Issuer: {
      subject: 'CN=PKI,OU=Example,O=World',
      subjectKeyIdentifier: 'AB:AB:AB:AB:AB:AB:AB:AB:',
    },
  },
};

export const x509CertificateDetailsProp = {
  title: 'Title',
  subject: 'CN=gitlab@example.org,OU=Example,O=World',
  subjectKeyIdentifier: 'BC BC BC BC BC BC BC BC',
};

export const tippingBranchesMock = ['main', 'development'];

export const containingBranchesMock = ['branch-1', 'branch-2', 'branch-3'];

export const mockCommitReferencesResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      commitReferences: {
        containingBranches: { names: ['branch-1'], __typename: 'CommitParentNames' },
        containingTags: { names: ['tag-1'], __typename: 'CommitParentNames' },
        tippingBranches: { names: tippingBranchesMock, __typename: 'CommitParentNames' },
        tippingTags: { names: ['tag-latest'], __typename: 'CommitParentNames' },
        __typename: 'CommitReferences',
      },
      __typename: 'Project',
    },
  },
};

export const mockOnlyBranchesResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      commitReferences: {
        containingBranches: { names: ['branch-1'], __typename: 'CommitParentNames' },
        containingTags: { names: [], __typename: 'CommitParentNames' },
        tippingBranches: { names: tippingBranchesMock, __typename: 'CommitParentNames' },
        tippingTags: { names: [], __typename: 'CommitParentNames' },
        __typename: 'CommitReferences',
      },
      __typename: 'Project',
    },
  },
};

export const mockContainingBranchesResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      commitReferences: {
        containingBranches: { names: containingBranchesMock, __typename: 'CommitParentNames' },
        __typename: 'CommitReferences',
      },
      __typename: 'Project',
    },
  },
};

export const refsListPropsMock = {
  hasContainingRefs: true,
  containingRefs: [],
  namespace: 'Branches',
  tippingRefs: tippingBranchesMock,
  isLoading: false,
  urlPart: '/some/project/-/commits/',
  refType: 'heads',
};
