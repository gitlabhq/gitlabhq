# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::CommitsFinder, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:finder) { described_class.new(project, params) }
  let(:params) { {} }

  shared_examples 'returns empty when repository does not exist' do
    context 'when the repository does not exist' do
      let_it_be(:empty_project) { create(:project) }

      let(:finder) { described_class.new(empty_project, params) }

      it 'returns an empty array' do
        expect(commits).to eq([])
      end
    end
  end

  describe '#execute' do
    context 'with offset pagination (gitaly_pagination: false)' do
      subject(:commits) { finder.execute(gitaly_pagination: false) }

      context 'when no params are given' do
        it 'returns commits from the default branch' do
          expect(commits).to be_present
          expect(commits).to be_a(CommitCollection)
        end
      end

      context 'when ref_name is specified' do
        let(:params) { { ref_name: 'feature' } }

        it 'returns commits from the specified branch' do
          expect(commits).to be_present

          default_commits = described_class.new(project, {}).execute(gitaly_pagination: false)
          expect(commits.first.id).not_to eq(default_commits.first.id)
        end
      end

      context 'when author is specified' do
        let(:params) { { author: 'Dmitriy Zaporozhets' } }

        it 'filters commits by author' do
          expect(commits).to be_present
          expect(commits).to all(satisfy { |c| c.author_name == 'Dmitriy Zaporozhets' })
        end
      end

      context 'when since and until are specified' do
        let(:params) { { since: 2.days.ago, until: Time.current } }

        it 'does not raise an error' do
          expect { commits }.not_to raise_error
        end
      end

      context 'when path has leading slashes' do
        using RSpec::Parameterized::TableSyntax

        where(:input_path, :expected_path) do
          '/README.md'    | 'README.md'
          '///README.md'  | 'README.md'
          'README.md'     | 'README.md'
        end

        with_them do
          let(:params) { { path: input_path } }

          it 'sanitizes the path by stripping leading slashes' do
            expect(project.repository).to receive(:commits).with(
              anything,
              hash_including(path: expected_path)
            ).and_call_original

            commits
          end
        end
      end

      context 'with simple parameter filtering' do
        using RSpec::Parameterized::TableSyntax

        where(:filter_desc, :param_name, :param_value) do
          'all refs'       | :all          | true
          'path'           | :path         | 'README.md'
          'first parent'   | :first_parent | true
          'topo order'     | :order        | 'topo'
        end

        with_them do
          let(:params) { { param_name => param_value } }

          it 'returns commits when filtering by the given parameter' do
            expect(commits).to be_present
          end
        end
      end

      context 'when both all and ref_name are specified' do
        let(:params) { { all: true, ref_name: 'feature' } }

        it 'gives precedence to all over ref_name' do
          expect(project.repository).to receive(:commits).with(
            nil,
            hash_including(all: true)
          ).and_call_original

          commits
        end
      end

      context 'when per_page and page are specified' do
        let(:params) { { per_page: 5, page: 1 } }

        it 'limits the number of commits returned' do
          expect(commits.size).to be <= 5
        end

        context 'with page 2' do
          let(:params) { { per_page: 5, page: 2 } }

          it 'returns a different set of commits' do
            first_page = described_class.new(project, { per_page: 5, page: 1 }).execute(gitaly_pagination: false)
            expect(commits.map(&:id)).not_to eq(first_page.map(&:id))
          end
        end
      end

      it_behaves_like 'returns empty when repository does not exist'
    end

    context 'with gitaly pagination (gitaly_pagination: true)' do
      subject(:commits) { finder.execute(gitaly_pagination: true) }

      context 'when no params are given' do
        it 'returns commits from the default branch' do
          expect(commits).to be_present
          expect(commits).to be_a(Repositories::CommitCollectionWithNextCursor)
        end
      end

      context 'when ref_name is specified' do
        let(:params) { { ref_name: 'feature' } }

        it 'returns commits from the specified branch' do
          expect(commits).to be_present
        end
      end

      context 'when all is true' do
        let(:params) { { all: true } }

        it 'passes --all as the ref to list_commits' do
          expect(project.repository).to receive(:list_commits).with(
            hash_including(ref: '--all')
          ).and_call_original

          commits
        end

        it 'returns commits' do
          expect(commits).to be_present
        end
      end

      context 'when both all and ref_name are specified' do
        let(:params) { { all: true, ref_name: 'feature' } }

        it 'gives precedence to all over ref_name' do
          expect(project.repository).to receive(:list_commits).with(
            hash_including(ref: '--all')
          ).and_call_original

          commits
        end
      end

      context 'when author is specified' do
        let(:params) { { author: 'Dmitriy Zaporozhets' } }

        it 'passes author to list_commits' do
          expect(project.repository).to receive(:list_commits).with(
            hash_including(author: 'Dmitriy Zaporozhets')
          ).and_call_original

          commits
        end
      end

      context 'when since and until are specified' do
        let(:since_time) { 2.days.ago }
        let(:until_time) { Time.current }
        let(:params) { { since: since_time, until: until_time } }

        it 'passes time filters to list_commits' do
          expect(project.repository).to receive(:list_commits).with(
            hash_including(committed_after: since_time, committed_before: until_time)
          ).and_call_original

          commits
        end
      end

      context 'when path is specified' do
        let(:params) { { path: 'files/ruby/popen.rb' } }

        it 'passes the sanitized path to list_commits' do
          expect(project.repository).to receive(:list_commits).with(
            hash_including(path: 'files/ruby/popen.rb')
          ).and_call_original

          commits
        end

        it 'passes literal_pathspec: true to match offset behavior' do
          expect(project.repository).to receive(:list_commits).with(
            hash_including(literal_pathspec: true)
          ).and_call_original

          commits
        end

        it 'returns the same commits as offset pagination for the path' do
          offset_commits = described_class.new(project, params).execute(gitaly_pagination: false)

          expect(commits).to be_present
          expect(commits.map(&:id)).to match_array(offset_commits.map(&:id))
        end

        context 'when path has leading slashes' do
          let(:params) { { path: '/files/ruby/popen.rb' } }

          it 'strips leading slashes before passing to list_commits' do
            expect(project.repository).to receive(:list_commits).with(
              hash_including(path: 'files/ruby/popen.rb')
            ).and_call_original

            commits
          end
        end

        context 'when the path contains a glob metacharacter' do
          # Commit a file whose name literally contains a glob metacharacter to
          # an isolated branch, so the tests compare against real, non-empty data
          # instead of an empty result. The branch keeps the shared fixture repo's
          # default branch pristine for sibling examples.
          let_it_be(:user) { project.first_owner }
          let_it_be(:literal_path) { 'files/ruby/star*.rb' }
          let_it_be(:glob_branch) do
            project.repository.create_file(
              user, literal_path, 'puts "star"',
              message: 'Add file with a literal glob metacharacter',
              branch_name: 'glob-metacharacter-test',
              start_branch_name: project.default_branch
            )

            'glob-metacharacter-test'
          end

          it 'matches offset pagination for the literal path' do
            params = { ref_name: glob_branch, path: literal_path }
            keyset_commits = described_class.new(project, params).execute(gitaly_pagination: true)
            offset_commits = described_class.new(project, params).execute(gitaly_pagination: false)

            expect(keyset_commits).to be_present
            expect(offset_commits).to be_present
            expect(keyset_commits.map(&:id)).to match_array(offset_commits.map(&:id))
          end

          it 'treats the path literally rather than expanding the glob' do
            # files/ruby/*.rb would match popen.rb, regex.rb, etc. if expanded,
            # but literal_pathspec: true means it matches nothing. Both modes must
            # agree on the empty result, proving the glob is not expanded.
            params = { ref_name: glob_branch, path: 'files/ruby/*.rb' }
            keyset_commits = described_class.new(project, params).execute(gitaly_pagination: true)
            offset_commits = described_class.new(project, params).execute(gitaly_pagination: false)

            expect(keyset_commits).to be_empty
            expect(offset_commits).to be_empty
            expect(keyset_commits.map(&:id)).to eq(offset_commits.map(&:id))
          end
        end
      end

      context 'when per_page is specified' do
        let(:params) { { per_page: 5 } }

        it 'limits the number of commits returned' do
          expect(commits.size).to be <= 5
        end
      end

      context 'when page_token is specified' do
        it 'paginates using the cursor' do
          first_page_finder = described_class.new(project, { per_page: 5 })
          first_page = first_page_finder.execute(gitaly_pagination: true)
          cursor = first_page_finder.next_cursor

          next_page_finder = described_class.new(project, { per_page: 5, page_token: cursor })
          second_page = next_page_finder.execute(gitaly_pagination: true)

          expect(second_page).to be_present
          expect(second_page.map(&:id)).not_to include(*first_page.map(&:id))
        end
      end

      it_behaves_like 'returns empty when repository does not exist'

      context 'with parameter validation' do
        using RSpec::Parameterized::TableSyntax

        where(:param_name, :param_value) do
          'first_parent' | true
          'order'        | 'topo'
          'trailers'     | true
          'follow'       | true
        end

        with_them do
          let(:params) { { param_name.to_sym => param_value } }

          it "raises UnsupportedKeysetParamError for unsupported param" do
            expect { commits }.to raise_error(described_class::UnsupportedKeysetParamError) do |error|
              expect(error).to be_a(ArgumentError)
              expect(error.message).to include("'#{param_name}'")
              expect(error.message).to include(described_class::KEYSET_PARAM_ERROR_SUFFIX)
            end
          end
        end

        context 'when multiple unsupported params are given' do
          let(:params) { { first_parent: true, follow: true } }

          it 'raises UnsupportedKeysetParamError listing all unsupported params' do
            expect { commits }.to raise_error(described_class::UnsupportedKeysetParamError) do |error|
              expect(error.message).to include("'first_parent'")
              expect(error.message).to include("'follow'")
              expect(error.message).to include(described_class::KEYSET_PARAM_ERROR_SUFFIX)
            end
          end
        end

        context 'when order is default' do
          let(:params) { { order: 'default' } }

          it 'does not raise an error' do
            expect { commits }.not_to raise_error
          end
        end
      end
    end
  end

  describe '#next_cursor' do
    subject(:next_cursor) { finder.next_cursor }

    it 'is nil before execute is called' do
      expect(next_cursor).to be_nil
    end

    context 'when offset pagination was used' do
      before do
        finder.execute(gitaly_pagination: false)
      end

      it 'is nil' do
        expect(next_cursor).to be_nil
      end
    end

    context 'when gitaly pagination was used' do
      context 'when there are more results' do
        let(:params) { { per_page: 5 } }

        before do
          finder.execute(gitaly_pagination: true)
        end

        it 'is present' do
          expect(next_cursor).to be_present
        end
      end

      context 'when all results fit on one page' do
        let(:params) { { per_page: 1000 } }

        before do
          finder.execute(gitaly_pagination: true)
        end

        it 'is nil' do
          expect(next_cursor).to be_nil
        end
      end
    end
  end
end
