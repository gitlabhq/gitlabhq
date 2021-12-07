import updateDescription from '~/issues/show/utils/update_description';

describe('updateDescription', () => {
  it('returns the correct value to be set as descriptionHtml', () => {
    const actual = updateDescription(
      '<details><summary>One</summary></details><details><summary>Two</summary></details>',
      [{ open: true }, { open: false }], // mocking NodeList from the dom.
    );

    expect(actual).toEqual(
      '<details open="true"><summary>One</summary></details><details><summary>Two</summary></details>',
    );
  });

  describe('when description details returned from api is different then whats currently on the dom', () => {
    it('returns the description from the api', () => {
      const dataDescription = '<details><summary>One</summary></details>';

      const actual = updateDescription(dataDescription, []);

      expect(actual).toEqual(dataDescription);
    });
  });
});
