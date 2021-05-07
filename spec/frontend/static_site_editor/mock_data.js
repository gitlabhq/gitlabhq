export const sourceContentHeaderYAML = `---
layout: handbook-page-toc
title: Handbook
twitter_image: /images/tweets/handbook-gitlab.png
suppress_header: true
extra_css:
  - sales-and-free-trial-common.css
  - form-to-resource.css
---`;
export const sourceContentHeaderObjYAML = {
  layout: 'handbook-page-toc',
  title: 'Handbook',
  twitter_image: '/images/tweets/handbook-gitlab.png',
  suppress_header: true,
  extra_css: ['sales-and-free-trial-common.css', 'form-to-resource.css'],
};
export const sourceContentSpacing = `\n`;
export const sourceContentBody = `## On this page
{:.no_toc .hidden-md .hidden-lg}

- TOC
{:toc .hidden-md .hidden-lg}

![image](path/to/image1.png)`;
export const sourceContentYAML = `${sourceContentHeaderYAML}${sourceContentSpacing}${sourceContentBody}`;
export const sourceContentTitle = 'Handbook';

export const username = 'gitlabuser';
export const projectId = '123456';
export const project = 'user1/project1';
export const returnUrl = 'https://www.gitlab.com';
export const sourcePath = 'foobar.md.html';
export const mergeRequestMeta = {
  title: `Update ${sourcePath} file`,
  description: 'Copy update',
};
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
export const mergeRequestTemplates = [
  { key: 'Template1', name: 'Template 1', content: 'This is template 1!' },
  { key: 'Template2', name: 'Template 2', content: 'This is template 2!' },
];

export const submitChangesError = 'Could not save changes';
export const commitBranchResponse = {
  web_url: '/tree/root-main-patch-88195',
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

export const images = new Map([
  ['path/to/image1.png', 'image1-content'],
  ['path/to/image2.png', 'image2-content'],
]);

export const mounts = [
  {
    source: 'default/source/',
    target: '',
  },
  {
    source: 'source/with/target',
    target: 'target',
  },
];

export const branch = 'main';

export const baseUrl = '/user1/project1/-/sse/main%2Ftest.md';

export const imageRoot = 'source/images/';
