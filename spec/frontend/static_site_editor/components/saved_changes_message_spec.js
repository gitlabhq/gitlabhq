import { shallowMount } from '@vue/test-utils';

import SavedChangesMessage from '~/static_site_editor/components/saved_changes_message.vue';

import { returnUrl, savedContentMeta } from '../mock_data';

describe('~/static_site_editor/components/saved_changes_message.vue', () => {
  let wrapper;
  const { branch, commit, mergeRequest } = savedContentMeta;
  const props = {
    branch,
    commit,
    mergeRequest,
    returnUrl,
  };
  const findReturnToSiteButton = () => wrapper.find({ ref: 'returnToSiteButton' });
  const findMergeRequestButton = () => wrapper.find({ ref: 'mergeRequestButton' });
  const findBranchLink = () => wrapper.find({ ref: 'branchLink' });
  const findCommitLink = () => wrapper.find({ ref: 'commitLink' });
  const findMergeRequestLink = () => wrapper.find({ ref: 'mergeRequestLink' });

  beforeEach(() => {
    wrapper = shallowMount(SavedChangesMessage, {
      propsData: props,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    text                    | findEl                    | url
    ${'Return to site'}     | ${findReturnToSiteButton} | ${props.returnUrl}
    ${'View merge request'} | ${findMergeRequestButton} | ${props.mergeRequest.url}
  `('renders "$text" button link', ({ text, findEl, url }) => {
    const btn = findEl();

    expect(btn.exists()).toBe(true);
    expect(btn.text()).toBe(text);
    expect(btn.attributes('href')).toBe(url);
  });

  it.each`
    desc               | findEl                  | prop
    ${'branch'}        | ${findBranchLink}       | ${props.branch}
    ${'commit'}        | ${findCommitLink}       | ${props.commit}
    ${'merge request'} | ${findMergeRequestLink} | ${props.mergeRequest}
  `('renders $desc link', ({ desc, findEl, prop }) => {
    const el = findEl();

    expect(el.exists()).toBe(true);
    expect(el.text()).toBe(prop.label);

    if (desc !== 'branch') {
      expect(el.attributes('href')).toBe(prop.url);
    }
  });
});
