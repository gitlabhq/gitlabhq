import BlobForkSuggestion from '~/blob/blob_fork_suggestion';

describe('BlobForkSuggestion', () => {
  let blobForkSuggestion;

  const openButton = document.createElement('div');
  const forkButton = document.createElement('a');
  const cancelButton = document.createElement('div');
  const suggestionSection = document.createElement('div');
  const actionTextPiece = document.createElement('div');

  const getSuggestionsNodeList = () => {
    const container = document.createElement('div');
    container.innerHTML = `
    <div class="suggestion-section"></div>
    <div class="suggestion-section"></div>
  `;

    return container.querySelectorAll('.suggestion-section');
  };

  const getSuggestionsArray = () => [document.createElement('div'), document.createElement('div')];

  beforeEach(() => {
    blobForkSuggestion = new BlobForkSuggestion({
      openButtons: openButton,
      forkButtons: forkButton,
      cancelButtons: cancelButton,
      suggestionSections: suggestionSection,
      actionTextPieces: actionTextPiece,
    }).init();
  });

  afterEach(() => {
    blobForkSuggestion.destroy();
  });

  it('showSuggestionSection', () => {
    blobForkSuggestion.showSuggestionSection('/foo', 'foo');

    expect(suggestionSection.classList.contains('hidden')).toEqual(false);
    expect(forkButton.getAttribute('href')).toEqual('/foo');
    expect(actionTextPiece.textContent).toEqual('foo');
  });

  it('hideSuggestionSection', () => {
    blobForkSuggestion.hideSuggestionSection();

    expect(suggestionSection.classList.contains('hidden')).toEqual(true);
  });

  describe.each([
    ['NodeList', getSuggestionsNodeList],
    ['Array', getSuggestionsArray],
  ])('with multiple elements (%s)', (_, buildSections) => {
    let suggestionSections;

    beforeEach(() => {
      suggestionSections = buildSections();
      blobForkSuggestion = new BlobForkSuggestion({ suggestionSections }).init();
    });

    it('hides all sections', () => {
      blobForkSuggestion.hideSuggestionSection();

      suggestionSections.forEach((el) => {
        expect(el.classList.contains('hidden')).toBe(true);
      });
    });
  });
});
