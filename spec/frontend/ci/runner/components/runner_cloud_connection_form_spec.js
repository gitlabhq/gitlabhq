import { GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCloudConnectionForm from '~/ci/runner/components/runner_cloud_connection_form.vue';

describe('Runner Cloud Connection Form', () => {
  let wrapper;

  const findWifSetupBtn = () => wrapper.findByTestId('wif-setup-btn');
  const findCloudSetupBtn = () => wrapper.findByTestId('cloud-setup-btn');
  const findContinueBtn = () => wrapper.findByTestId('continue-btn');
  const findCloudDrawer = () => wrapper.findByTestId('cloud-drawer');
  const findWifDrawer = () => wrapper.findByTestId('wif-drawer');
  const findResourceInput = () => wrapper.findByTestId('resource-input');
  const findProjectIdInput = () => wrapper.findByTestId('project-id-input');
  const findDocsLink = () => wrapper.findComponent(GlLink);

  const createComponent = (mountFn = shallowMountExtended) => {
    wrapper = mountFn(RunnerCloudConnectionForm);
  };

  it('displays all inputs', () => {
    createComponent();

    expect(findResourceInput().exists()).toBe(true);
    expect(findProjectIdInput().exists()).toBe(true);
  });

  it('opens wif drawer', async () => {
    createComponent();

    expect(findWifDrawer().props('open')).toBe(false);

    findWifSetupBtn().vm.$emit('click');

    await nextTick();

    expect(findWifDrawer().props('open')).toBe(true);
  });

  it('opens google cloud project drawer', async () => {
    createComponent();

    expect(findCloudDrawer().props('open')).toBe(false);

    findCloudSetupBtn().vm.$emit('click');

    await nextTick();

    expect(findCloudDrawer().props('open')).toBe(true);
  });

  it('two drawers cannot be displayed at once', async () => {
    createComponent();

    expect(findWifDrawer().props('open')).toBe(false);
    expect(findCloudDrawer().props('open')).toBe(false);

    findWifSetupBtn().vm.$emit('click');

    await nextTick();

    expect(findWifDrawer().props('open')).toBe(true);

    findCloudSetupBtn().vm.$emit('click');

    await nextTick();

    expect(findWifDrawer().props('open')).toBe(false);
    expect(findCloudDrawer().props('open')).toBe(true);
  });

  it('contains external docs link', () => {
    createComponent(mountExtended);

    expect(findDocsLink().attributes('href')).toBe(
      'https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects',
    );
  });

  it('emits cloud connection data', () => {
    createComponent(mountExtended);

    const resourcePath = 'resource-path';
    const projectId = '12';

    findResourceInput().vm.$emit('input', resourcePath);
    findProjectIdInput().vm.$emit('input', projectId);

    findContinueBtn().vm.$emit('click');

    expect(wrapper.emitted()).toMatchObject({ continue: [[{ projectId, resourcePath }]] });
  });
});
