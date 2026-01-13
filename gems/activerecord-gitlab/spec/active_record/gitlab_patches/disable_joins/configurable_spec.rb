# frozen_string_literal: true

RSpec.describe ActiveRecord::GitlabPatches::DisableJoins::Configurable do
  # Create model subclasses with has_many :through associations
  let(:project_with_no_disable_joins) do
    Class.new(Project) do
      self.table_name = :projects

      has_many :jobs,
        through: :pipelines,
        source: :jobs
    end
  end

  let(:project_with_static_disable_joins) do
    Class.new(Project) do
      self.table_name = :projects

      has_many :jobs_with_static_disable_joins,
        through: :pipelines,
        source: :jobs,
        disable_joins: true
    end
  end

  let(:project_with_proc_disable_joins) do
    Class.new(Project) do
      self.table_name = :projects

      has_many :jobs_with_proc_disable_joins,
        through: :pipelines,
        source: :jobs,
        disable_joins: proc { true }
    end
  end

  let(:project_with_dynamic_proc_disable_joins) do
    Class.new(Project) do
      self.table_name = :projects

      class_attribute :disable_joins_flag

      has_many :jobs_with_dynamic_disable_joins,
        through: :pipelines,
        source: :jobs,
        disable_joins: proc { disable_joins_flag }
    end
  end

  let(:project_with_false_disable_joins) do
    Class.new(Project) do
      self.table_name = :projects

      has_many :jobs_with_false_disable_joins,
        through: :pipelines,
        source: :jobs,
        disable_joins: false
    end
  end

  describe '#disable_joins' do
    context 'when no disable_joins is configured' do
      it 'returns default false' do
        association = project_with_no_disable_joins.new.association(:jobs)

        expect(association.disable_joins).to be false
      end
    end

    context 'when disable_joins is a boolean true' do
      it 'returns true' do
        association = project_with_static_disable_joins.new.association(:jobs_with_static_disable_joins)

        expect(association.disable_joins).to be true
      end
    end

    context 'when disable_joins is a boolean false' do
      it 'returns false' do
        association = project_with_false_disable_joins.new.association(:jobs_with_false_disable_joins)

        expect(association.disable_joins).to be false
      end
    end

    context 'when disable_joins is a Proc' do
      it 'calls the Proc and returns its result' do
        association = project_with_proc_disable_joins.new.association(:jobs_with_proc_disable_joins)

        expect(association.disable_joins).to be true
      end

      it 'evaluates the Proc with the self as context' do
        project_with_dynamic_proc_disable_joins.disable_joins_flag = true

        association = project_with_dynamic_proc_disable_joins.new.association(:jobs_with_dynamic_disable_joins)

        expect(association.disable_joins).to be true
      end

      it 're-evaluates the Proc on each access' do
        association = project_with_dynamic_proc_disable_joins.new.association(:jobs_with_dynamic_disable_joins)

        project_with_dynamic_proc_disable_joins.disable_joins_flag = true
        expect(association.disable_joins).to be true

        project_with_dynamic_proc_disable_joins.disable_joins_flag = false
        expect(association.disable_joins).to be false

        project_with_dynamic_proc_disable_joins.disable_joins_flag = true
        expect(association.disable_joins).to be true
      end
    end
  end

  describe 'integration with ActiveRecord::Associations::Association' do
    it 'prepends the module to Association class' do
      expect(::ActiveRecord::Associations::Association.ancestors)
        .to include(described_class)
    end
  end
end
