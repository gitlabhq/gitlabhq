export const MOCK_HTML = `<!DOCTYPE html>
<html>
<body>
  <div id="content-body">
    <h1>test title <strong>test</strong></h1>
    <div class="documentation md gl-mt-3">
      <a href="../advanced_search.md">Advanced Search</a>
      <a href="../advanced_search2.md">Advanced Search2</a>
      <h2>test header h2</h2>
      <table class="testClass">
        <tr>
          <td>Emil</td>
          <td>Tobias</td>
          <td>Linus</td>
        </tr>
        <tr>
          <td>16</td>
          <td>14</td>
          <td>10</td>
        </tr>
      </table>
    </div>
  </div>
</body>
</html>`.replace(/\n/g, '');

export const MOCK_DRAWER_DATA = {
  hasFetchError: false,
  title: 'test title test',
  body: `  <div id="content-body">        <div class="documentation md gl-mt-3">      <a href="../advanced_search.md">Advanced Search</a>      <a href="../advanced_search2.md">Advanced Search2</a>      <h2>test header h2</h2>      <table class="testClass">        <tbody><tr>          <td>Emil</td>          <td>Tobias</td>          <td>Linus</td>        </tr>        <tr>          <td>16</td>          <td>14</td>          <td>10</td>        </tr>      </tbody></table>    </div>  </div>`,
};

export const MOCK_DRAWER_DATA_ERROR = {
  hasFetchError: true,
};

export const MOCK_TABLE_DATA_BEFORE = `<head></head><body><h1>test</h1></test><table><tbody><tr><td></td></tr></tbody></table></body>`;

export const MOCK_HTML_DATA_AFTER = {
  body: '<table><tbody><tr><td></td></tr></tbody></table>',
  title: 'test',
};
