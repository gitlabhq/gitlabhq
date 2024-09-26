import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewEnvironment from '~/environments/components/new_environment.vue';
import createEnvironment from '~/environments/graphql/mutations/create_environment.mutation.graphql';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import createMockApollo from '../__helpers__/mock_apollo_helper';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

const provide = {
  projectEnvironmentsPath: '/projects/environments',
  projectPath: '/path/to/project',
};

const environmentCreate = { environment: { id: '1', path: 'path/to/environment' }, errors: [] };
const environmentCreateError = {
  environment: null,
  errors: [{ message: 'uh oh!' }],
};

describe('~/environments/components/new.vue', () => {
  let wrapper;

  const createMockApolloProvider = (mutationResult) => {
    Vue.use(VueApollo);

    return createMockApollo([
      [
        createEnvironment,
        jest.fn().mockResolvedValue({ data: { environmentCreate: mutationResult } }),
      ],
    ]);
  };

  const createWrapperWithApollo = async (mutationResult = environmentCreate) => {
    wrapper = mountExtended(NewEnvironment, {
      provide,
      apolloProvider: createMockApolloProvider(mutationResult),
    });

    await waitForPromises();
  };

  const findNameInput = () => wrapper.findByLabelText('Name');
  const findExternalUrlInput = () => wrapper.findByLabelText('External URL');
  const findForm = () => wrapper.findByRole('form', { name: 'New environment' });
  const showsLoading = () => wrapper.findByTestId('save-environment').props('loading');

  const submitForm = async () => {
    await findNameInput().setValue('test');
    await findExternalUrlInput().setValue('https://google.ca');

    await findForm().trigger('submit');
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapperWithApollo();
    });

    it('sets the title to New environment', () => {
      const header = wrapper.findByRole('heading', { name: 'New environment' });
      expect(header.exists()).toBe(true);
    });

    it.each`
      input                           | value
      ${() => findNameInput()}        | ${'test'}
      ${() => findExternalUrlInput()} | ${'https://example.org'}
    `('changes the value of the input to $value', ({ input, value }) => {
      input().setValue(value);

      expect(input().element.value).toBe(value);
    });
  });

  describe('when mutation successful', () => {
    beforeEach(() => {
      createWrapperWithApollo();
    });

    it('shows loader after form is submitted', async () => {
      expect(showsLoading()).toBe(false);

      await submitForm();

      expect(showsLoading()).toBe(true);
    });

    it('submits the new environment on submit', async () => {
      submitForm();
      await waitForPromises();

      expect(visitUrl).toHaveBeenCalledWith('path/to/environment');
    });
  });

  describe('when failed', () => {
    beforeEach(async () => {
      createWrapperWithApollo(environmentCreateError);
      submitForm();
      await waitForPromises();
    });

    it('display errors', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: 'uh oh!' });
      expect(showsLoading()).toBe(false);
    });
  });
});
