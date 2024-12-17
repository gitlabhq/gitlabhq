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
        detailsPath: '/root/trigger-downstream/-/pipelines/610',
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
        detailsPath: '/root/trigger-downstream/-/pipelines/610',
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
        detailsPath: '/root/trigger-downstream/-/pipelines/610',
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
