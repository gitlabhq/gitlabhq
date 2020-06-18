export const sourceContentHeader = `---
layout: handbook-page-toc
title: Handbook
twitter_image: '/images/tweets/handbook-gitlab.png'
---`;
export const sourceContentSpacing = `
`;
export const sourceContentBody = `## On this page
{:.no_toc .hidden-md .hidden-lg}

- TOC
{:toc .hidden-md .hidden-lg}
`;
export const sourceContent = `${sourceContentHeader}${sourceContentSpacing}${sourceContentBody}`;
export const sourceContentTitle = 'Handbook';

export const username = 'gitlabuser';
export const projectId = '123456';
export const returnUrl = 'https://www.gitlab.com';
export const sourcePath = 'foobar.md.html';

export const savedContentMeta = {
  branch: {
    label: 'foobar',
    url: 'foobar/-/tree/foobar',
  },
  commit: {
    label: 'c1461b08',
    url: 'foobar/-/c1461b08',
  },
  mergeRequest: {
    label: '123',
    url: 'foobar/-/merge_requests/123',
  },
};

export const submitChangesError = 'Could not save changes';
export const commitBranchResponse = {
  web_url: '/tree/root-master-patch-88195',
};
export const commitMultipleResponse = {
  short_id: 'ed899a2f4b5',
  web_url: '/commit/ed899a2f4b5',
};
export const createMergeRequestResponse = {
  iid: '123',
  web_url: '/merge_requests/123',
};

export const trackingCategory = 'projects:static_site_editor:show';
