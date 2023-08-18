import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { stubComponent } from 'helpers/stub_component';
import DeleteApplication from '~/admin/applications/components/delete_application.vue';

const path = 'application/path/1';
const name = 'Application name';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('DeleteApplication', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DeleteApplication, {
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            show: jest.fn(),
          },
        }),
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent({ ref: 'deleteForm' });

  beforeEach(() => {
    setHTMLFixture(`
      <button class="js-application-delete-button" data-path="${path}" data-name="${name}">Destroy</button>
    `);

    createComponent();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('the modal component', () => {
    beforeEach(() => {
      document.querySelector('.js-application-delete-button').click();
    });

    it('displays the modal component', () => {
      const modal = findModal();

      expect(modal.exists()).toBe(true);
      expect(modal.props('title')).toBe('Confirm destroy application');
      expect(modal.text()).toBe(`Are you sure that you want to destroy ${name}`);
    });

    describe('form', () => {
      it('matches the snapshot', () => {
        expect(findForm().element).toMatchSnapshot();
      });

      describe('form submission', () => {
        let formSubmitSpy;

        beforeEach(() => {
          formSubmitSpy = jest.spyOn(findForm().element, 'submit');
          findModal().vm.$emit('primary');
        });

        it('submits the form on the modal primary action', () => {
          expect(formSubmitSpy).toHaveBeenCalled();
        });
      });
    });
  });
});
