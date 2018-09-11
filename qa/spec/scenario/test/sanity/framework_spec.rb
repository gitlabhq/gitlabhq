describe QA::Scenario::Test::Sanity::Framework do
  it_behaves_like 'a QA scenario class' do
    let(:tags) { [:framework] }
  end
end
