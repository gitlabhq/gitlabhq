import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import { projectData } from 'jest/ide/mock_data';
import { TEST_HOST } from 'spec/test_constants';
import { getFirstCharacterCapitalized } from '~/lib/utils/text_utility';
import ProjectAvatarDefault from '~/vue_shared/components/deprecated_project_avatar/default.vue';

describe('ProjectAvatarDefault component', () => {
  const Component = Vue.extend(ProjectAvatarDefault);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      project: projectData,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders identicon if project has no avatar_url', (done) => {
    const expectedText = getFirstCharacterCapitalized(projectData.name);

    vm.project = {
      ...vm.project,
      avatar_url: null,
    };

    vm.$nextTick()
      .then(() => {
        const identiconEl = vm.$el.querySelector('.identicon');

        expect(identiconEl).not.toBe(null);
        expect(identiconEl.textContent.trim()).toEqual(expectedText);
      })
      .then(done)
      .catch(done.fail);
  });

  it('renders avatar image if project has avatar_url', (done) => {
    const avatarUrl = `${TEST_HOST}/images/home/nasa.svg`;

    vm.project = {
      ...vm.project,
      avatar_url: avatarUrl,
    };

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.avatar')).not.toBeNull();
        expect(vm.$el.querySelector('.identicon')).toBeNull();
        expect(vm.$el.querySelector('img')).toHaveAttr('src', avatarUrl);
      })
      .then(done)
      .catch(done.fail);
  });
});
