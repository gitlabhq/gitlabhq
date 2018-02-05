import SecretValues from '~/behaviors/secret_values';

export default () => {
  const secretVariableTable = document.querySelector('.js-secret-variable-table');
  if (secretVariableTable) {
    const secretVariableTableValues = new SecretValues({
      container: secretVariableTable,
    });
    secretVariableTableValues.init();
  }
};
