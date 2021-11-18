import { merge } from 'lodash';
import { GlTable, GlButton } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeployKeysTable from '~/admin/deploy_keys/components/table.vue';

describe('DeployKeysTable', () => {
  let wrapper;

  const defaultProvide = {
    createPath: '/admin/deploy_keys/new',
    deletePath: '/admin/deploy_keys/:id',
    editPath: '/admin/deploy_keys/:id/edit',
    emptyStateSvgPath: '/assets/illustrations/empty-state/empty-deploy-keys.svg',
  };

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(DeployKeysTable, {
      provide: merge({}, defaultProvide, provide),
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders page title', () => {
    createComponent();

    expect(wrapper.findByText(DeployKeysTable.i18n.pageTitle).exists()).toBe(true);
  });

  it('renders table', () => {
    createComponent();

    expect(wrapper.findComponent(GlTable).exists()).toBe(true);
  });

  it('renders `New deploy key` button', () => {
    createComponent();

    const newDeployKeyButton = wrapper.findComponent(GlButton);

    expect(newDeployKeyButton.text()).toBe(DeployKeysTable.i18n.newDeployKeyButtonText);
    expect(newDeployKeyButton.attributes('href')).toBe(defaultProvide.createPath);
  });
});
