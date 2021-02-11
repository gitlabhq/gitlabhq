import { serializeForm } from '~/lib/utils/forms';

const findForm = () => document.querySelector('.merge-request-form');
const serializeFormData = () => JSON.stringify(serializeForm(findForm()));

export default () => {
  const oldFormData = serializeFormData();

  const compareFormData = (e) => {
    const newFormData = serializeFormData();

    if (oldFormData !== newFormData) {
      e.preventDefault();
      // eslint-disable-next-line no-param-reassign
      e.returnValue = ''; // Chrome requires returnValue to be set
    }
  };

  window.addEventListener('beforeunload', compareFormData);

  findForm().addEventListener('submit', () =>
    window.removeEventListener('beforeunload', compareFormData),
  );
};
