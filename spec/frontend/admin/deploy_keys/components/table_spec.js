import { merge } from 'lodash';
import { GlLoadingIcon, GlEmptyState, GlPagination, GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import responseBody from 'test_fixtures/api/deploy_keys/index.json';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import DeployKeysTable from '~/admin/deploy_keys/components/table.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import { createAlert } from '~/alert';

jest.mock('~/api');
jest.mock('~/alert');
jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('DeployKeysTable', () => {
  let wrapper;

  const defaultProvide = {
    createPath: '/admin/deploy_keys/new',
    deletePath: '/admin/deploy_keys/:id',
    editPath: '/admin/deploy_keys/:id/edit',
    emptyStateSvgPath: '/assets/illustrations/empty-state/empty-deploy-keys.svg',
  };

  const deployKey = responseBody[0];
  const deployKey2 = responseBody[1];
  const deployKeyWithoutMd5Fingerprint = responseBody[2];

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(DeployKeysTable, {
      provide: merge({}, defaultProvide, provide),
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: `
            <div>
              <slot name="modal-title"></slot>
              <slot></slot>
              <slot name="modal-footer"></slot>
            </div>`,
        }),
      },
    });
  };

  const findCrud = () => wrapper.findComponent(CrudComponent);
  const findCrudTitle = () => wrapper.findByTestId('crud-title');
  const findEditButton = (index) =>
    wrapper.findAllByLabelText(DeployKeysTable.i18n.edit, { selector: 'a' }).at(index);
  const findRemoveButton = (index) =>
    wrapper.findAllByLabelText(DeployKeysTable.i18n.delete, { selector: 'button' }).at(index);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTimeAgoTooltip = (index) => wrapper.findAllComponents(TimeAgoTooltip).at(index);
  const findPagination = () => wrapper.findComponent(GlPagination);

  const expectDeployKeyIsRendered = (expectedDeployKey, expectedRowIndex) => {
    const editButton = findEditButton(expectedRowIndex);
    const timeAgoTooltip = findTimeAgoTooltip(expectedRowIndex);

    expect(wrapper.findByText(expectedDeployKey.title).exists()).toBe(true);

    expect(
      wrapper.findByText(expectedDeployKey.fingerprint_sha256, { selector: 'div' }).exists(),
    ).toBe(true);
    expect(timeAgoTooltip.exists()).toBe(true);
    expect(timeAgoTooltip.props('time')).toBe(expectedDeployKey.created_at);
    expect(editButton.exists()).toBe(true);
    expect(editButton.attributes('href')).toBe(`/admin/deploy_keys/${expectedDeployKey.id}/edit`);
    expect(findRemoveButton(expectedRowIndex).exists()).toBe(true);
  };

  const expectDeployKeyWithFingerprintIsRendered = (expectedDeployKey, expectedRowIndex) => {
    expect(wrapper.findByText(expectedDeployKey.fingerprint, { selector: 'div' }).exists()).toBe(
      true,
    );
    expectDeployKeyIsRendered(expectedDeployKey, expectedRowIndex);
  };

  const itRendersTheEmptyState = () => {
    it('renders empty state', () => {
      const emptyState = wrapper.findComponent(GlEmptyState);

      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props()).toMatchObject({
        svgPath: defaultProvide.emptyStateSvgPath,
        title: DeployKeysTable.i18n.emptyStateTitle,
        description: DeployKeysTable.i18n.emptyStateDescription,
      });
    });
  };

  it('renders page title', () => {
    createComponent();

    expect(wrapper.findByText(DeployKeysTable.i18n.pageTitle).exists()).toBe(true);
  });

  it('renders `New deploy key` button', () => {
    createComponent();

    const newDeployKeyButton = wrapper.findByTestId('new-deploy-key-button');

    expect(newDeployKeyButton.exists()).toBe(true);
    expect(newDeployKeyButton.attributes('href')).toBe(defaultProvide.createPath);
  });

  describe('when `/deploy_keys` API request is pending', () => {
    beforeEach(() => {
      Api.deployKeys.mockImplementation(() => new Promise(() => {}));
    });

    it('shows loading icon', async () => {
      createComponent();

      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when `/deploy_keys` API request is successful', () => {
    describe('when there are deploy keys', () => {
      beforeEach(() => {
        Api.deployKeys.mockResolvedValue({
          data: responseBody,
          headers: { 'x-total': `${responseBody.length}` },
        });

        createComponent();
      });

      it('renders card with the deploy keys', () => {
        expect(findCrud().exists()).toBe(true);
      });

      it('shows the correct number of deploy keys', () => {
        expect(findCrudTitle().text()).toMatchInterpolatedText(
          `Public deploy keys ${responseBody.length}`,
        );
      });

      it('renders deploy keys in table', () => {
        expectDeployKeyWithFingerprintIsRendered(deployKey, 0);
        expectDeployKeyWithFingerprintIsRendered(deployKey2, 1);
      });

      it('renders deploy keys that do not have an MD5 fingerprint', () => {
        expectDeployKeyIsRendered(deployKeyWithoutMd5Fingerprint, 2);
      });

      describe('when delete button is clicked', () => {
        it('asks user to confirm', async () => {
          await findRemoveButton(0).trigger('click');

          const modal = wrapper.findComponent(GlModal);
          const form = modal.find('form');
          const submitSpy = jest.spyOn(form.element, 'submit');

          expect(modal.props('visible')).toBe(true);
          expect(form.attributes('action')).toBe(`/admin/deploy_keys/${deployKey.id}`);
          expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
          expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
            'mock-csrf-token',
          );

          modal.vm.$emit('primary');

          expect(submitSpy).toHaveBeenCalled();
        });
      });
    });

    describe('pagination', () => {
      beforeEach(() => {
        Api.deployKeys.mockResolvedValueOnce({
          data: [deployKey],
          headers: { 'x-total': '3' },
        });

        createComponent();
      });

      it('renders pagination', () => {
        const pagination = findPagination();
        expect(pagination.exists()).toBe(true);
        expect(pagination.props()).toMatchObject({
          value: 1,
          perPage: DEFAULT_PER_PAGE,
          totalItems: responseBody.length,
          align: 'center',
        });
      });

      describe('when pagination is changed', () => {
        it('calls API with `page` parameter', async () => {
          const pagination = findPagination();
          expectDeployKeyWithFingerprintIsRendered(deployKey, 0);

          Api.deployKeys.mockResolvedValue({
            data: [deployKey2],
            headers: { 'x-total': '2' },
          });

          pagination.vm.$emit('input', 2);

          await nextTick();

          expect(findLoadingIcon().exists()).toBe(true);
          expect(pagination.exists()).toBe(false);

          await waitForPromises();

          expect(Api.deployKeys).toHaveBeenCalledWith({
            page: 2,
            public: true,
          });
          expectDeployKeyWithFingerprintIsRendered(deployKey2, 0);
        });
      });
    });

    describe('when there are no deploy keys', () => {
      beforeEach(() => {
        Api.deployKeys.mockResolvedValue({
          data: [],
          headers: { 'x-total': '0' },
        });

        createComponent();
      });

      itRendersTheEmptyState();
    });
  });

  describe('when `deploy_keys` API request is unsuccessful', () => {
    const error = new Error('Network Error');

    beforeEach(() => {
      Api.deployKeys.mockRejectedValue(error);

      createComponent();
    });

    itRendersTheEmptyState();

    it('displays alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: DeployKeysTable.i18n.apiErrorMessage,
        captureError: true,
        error,
      });
    });
  });
});
