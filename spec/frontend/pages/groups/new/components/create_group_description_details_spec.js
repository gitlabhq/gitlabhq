import { shallowMount } from '@vue/test-utils';
import { GlSprintf, GlLink } from '@gitlab/ui';
import CreateGroupDescriptionDetails from '~/pages/groups/new/components/create_group_description_details.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

describe('CreateGroupDescriptionDetails component', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(CreateGroupDescriptionDetails, {
      propsData,
      stubs: { GlSprintf, GlLink },
    });
  };

  const findLinkHref = (at) => wrapper.findAllComponents(GlLink).at(at);

  it('creates correct component for group creation', () => {
    createComponent();

    const groupsLink = findLinkHref(0);
    expect(groupsLink.attributes('href')).toBe(helpPagePath('user/group/_index'));
    expect(groupsLink.text()).toBe('Groups');

    const subgroupsLink = findLinkHref(1);
    expect(subgroupsLink.text()).toBe('subgroups');
    expect(subgroupsLink.attributes('href')).toBe(helpPagePath('user/group/subgroups/_index'));

    expect(wrapper.text()).toBe(
      'Groups allow you to manage and collaborate across multiple projects. Members of a group have access to all of its projects. Groups can also be nested by creating subgroups.',
    );
  });

  it('creates correct component for subgroup creation', () => {
    createComponent({ parentGroupName: 'parent', importExistingGroupPath: '/path' });

    const groupsLink = findLinkHref(0);
    expect(groupsLink.attributes('href')).toBe(helpPagePath('user/group/_index'));
    expect(groupsLink.text()).toBe('Groups');

    const subgroupsLink = findLinkHref(1);
    expect(subgroupsLink.text()).toBe('subgroups');
    expect(subgroupsLink.attributes('href')).toBe(helpPagePath('user/group/subgroups/_index'));

    const importGroupLink = findLinkHref(2);
    expect(importGroupLink.text()).toBe('import an existing group');
    expect(importGroupLink.attributes('href')).toBe('/path');

    expect(wrapper.text()).toBe(
      'Groups and subgroups allow you to manage and collaborate across multiple projects. Members of a group have access to all of its projects. You can also import an existing group.',
    );
  });
});
