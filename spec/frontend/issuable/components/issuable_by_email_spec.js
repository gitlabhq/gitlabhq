import { GlModal, GlSprintf, GlFormInputGroup, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import httpStatus from '~/lib/utils/http_status';

const initialEmail = 'user@gitlab.com';

const mockToastShow = jest.fn();

describe('IssuableByEmail', () => {
  let wrapper;
  let mockAxios;
  let glModalDirective;

  function createComponent(injectedProperties = {}) {
    glModalDirective = jest.fn();

    return extendedWrapper(
      shallowMount(IssuableByEmail, {
        stubs: {
          GlModal,
          GlSprintf,
          GlFormInputGroup,
          GlButton,
        },
        directives: {
          glModal: {
            bind(_, { value }) {
              glModalDirective(value);
            },
          },
        },
        mocks: {
          $toast: {
            show: mockToastShow,
          },
        },
        provide: {
          issuableType: 'issue',
          initialEmail,
          ...injectedProperties,
        },
      }),
    );
  }

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockAxios.restore();
  });

  const findButton = () => wrapper.findComponent(GlButton);
  const findFormInputGroup = () => wrapper.findComponent(GlFormInputGroup);

  const clickResetEmail = async () => {
    wrapper.findAllComponents(GlButton).at(2).trigger('click');

    await waitForPromises();
  };

  describe('modal button', () => {
    it.each`
      issuableType       | buttonText
      ${'issue'}         | ${'Email a new issue to this project'}
      ${'merge_request'} | ${'Email a new merge request to this project'}
    `(
      'renders a link with "$buttonText" when type is "$issuableType"',
      ({ issuableType, buttonText }) => {
        wrapper = createComponent({ issuableType });
        expect(findButton().text()).toBe(buttonText);
      },
    );

    it('opens the modal when the user clicks the button', () => {
      wrapper = createComponent();

      findButton().trigger('click');

      expect(glModalDirective).toHaveBeenCalled();
    });
  });

  describe('modal', () => {
    it('renders a read-only email input field', () => {
      wrapper = createComponent();

      expect(findFormInputGroup().props('value')).toBe('user@gitlab.com');
    });

    it.each`
      issuableType       | subject                            | body
      ${'issue'}         | ${'Enter the issue title'}         | ${'Enter the issue description'}
      ${'merge_request'} | ${'Enter the merge request title'} | ${'Enter the merge request description'}
    `('renders a mailto button when type is "$issuableType"', ({ issuableType, subject, body }) => {
      wrapper = createComponent({
        issuableType,
        initialEmail,
      });

      expect(wrapper.findAllComponents(GlButton).at(1).attributes('href')).toBe(
        `mailto:${initialEmail}?subject=${subject}&body=${body}`,
      );
    });

    describe('reset email', () => {
      const resetPath = 'gitlab-test/new_issuable_address?issuable_type=issue';

      beforeEach(() => {
        jest.spyOn(axios, 'put');
      });
      it('should send request to reset email token', async () => {
        wrapper = createComponent({
          issuableType: 'issue',
          initialEmail,
          resetPath,
        });

        await clickResetEmail();

        expect(axios.put).toHaveBeenCalledWith(resetPath);
      });

      it('should update the email when the request succeeds', async () => {
        mockAxios.onPut(resetPath).reply(httpStatus.OK, { new_address: 'foo@bar.com' });

        wrapper = createComponent({
          issuableType: 'issue',
          initialEmail,
          resetPath,
        });

        await clickResetEmail();

        expect(findFormInputGroup().props('value')).toBe('foo@bar.com');
      });

      it('should show a toast message when the request fails', async () => {
        mockAxios.onPut(resetPath).reply(httpStatus.NOT_FOUND, {});

        wrapper = createComponent({
          issuableType: 'issue',
          initialEmail,
          resetPath,
        });

        await clickResetEmail();

        expect(mockToastShow).toHaveBeenCalledWith('There was an error when reseting email token.');
        expect(findFormInputGroup().props('value')).toBe('user@gitlab.com');
      });
    });
  });
});
